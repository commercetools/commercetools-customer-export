path = require 'path'
_ = require 'underscore'
Promise = require 'bluebird'
fs = Promise.promisifyAll require('fs')
tmp = Promise.promisifyAll require('tmp')
{ExtendedLogger, ProjectCredentialsConfig, Sftp} = require 'sphere-node-utils'
package_json = require '../package.json'
CustomerExport = require './customerexport'

argv = require('optimist')
  .usage('Usage: $0 --projectKey key --clientId id --clientSecret secret')
  .describe('projectKey', 'your commercetools platform project-key')
  .describe('clientId', 'your OAuth client id for the commercetools platform API')
  .describe('clientSecret', 'your OAuth client secret for the commercetools platform API')
  .describe('accessToken', 'an OAuth access token for the SPHERE.IO API, used instead of clientId and clientSecret')
  .describe('sphereHost', 'SPHERE.IO API host to connect to')
  .describe('where', 'where predicate used to filter customers exported. More info here http://dev.commercetools.com/http-api.html#predicates')
  .describe('targetDir', 'the folder where exported files are saved')
  .describe('useExportTmpDir', 'whether to use a system tmp folder to store exported files')
  .describe('csvTemplate', 'CSV template to define the structure of the export')
  .describe('fileWithTimestamp', 'whether exported file should contain a timestamp')
  .describe('sftpCredentials', 'the path to a JSON file where to read the credentials from')
  .describe('sftpHost', 'the SFTP host (overwrite value in sftpCredentials JSON, if given)')
  .describe('sftpUsername', 'the SFTP username (overwrite value in sftpCredentials JSON, if given)')
  .describe('sftpPassword', 'the SFTP password (overwrite value in sftpCredentials JSON, if given)')
  .describe('sftpTarget', 'path in the SFTP server to where to move the worked files')
  .describe('sftpContinueOnProblems', 'ignore errors when processing a file and continue with the next one')
  .describe('logLevel', 'log level for file logging')
  .describe('logDir', 'directory to store logs')
  .describe('logSilent', 'use console to print messages')
  .describe('timeout', 'Set timeout for requests')
  .default('targetDir', path.join(__dirname,'../exports'))
  .default('useExportTmpDir', false)
  .default('fileWithTimestamp', false)
  .default('logLevel', 'info')
  .default('logDir', '.')
  .default('logSilent', false)
  .default('timeout', 60000)
  .default('sftpContinueOnProblems', false)
  .demand(['projectKey'])
  .argv

logOptions =
  name: "#{package_json.name}-#{package_json.version}"
  streams: [
    { level: 'error', stream: process.stderr }
    { level: argv.logLevel, path: "#{argv.logDir}/#{package_json.name}.log" }
  ]
logOptions.silent = argv.logSilent if argv.logSilent
logger = new ExtendedLogger
  additionalFields:
    project_key: argv.projectKey
  logConfig: logOptions
if argv.logSilent
  logger.bunyanLogger.trace = -> # noop
  logger.bunyanLogger.debug = -> # noop

process.on 'exit', => process.exit(@exitCode)

tmp.setGracefulCleanup()

fsExistsAsync = (path) ->
  new Promise (resolve, reject) ->
    fs.exists path, (exists) ->
      if exists
        resolve(true)
      else
        resolve(false)

ensureExportDir = ->
  if "#{argv.useExportTmpDir}" is 'true'
    # unsafeCleanup: recursively removes the created temporary directory, even when it's not empty
    tmp.dirAsync {unsafeCleanup: true}
  else
    exportsPath = argv.targetDir
    fsExistsAsync(exportsPath)
    .then (exists) ->
      if exists
        Promise.resolve(exportsPath)
      else
        fs.mkdirAsync(exportsPath)
        .then -> Promise.resolve(exportsPath)

readJsonFromPath = (path) ->
  return Promise.resolve({}) unless path
  fs.readFileAsync(path, {encoding: 'utf-8'}).then (content) ->
    Promise.resolve JSON.parse(content)

ensureCredentials = ({ accessToken, projectKey, clientId, clientSecret }) ->
  if accessToken
    Promise.resolve
      config:
        project_key: projectKey
      access_token: accessToken
  else
    ProjectCredentialsConfig.create()
    .then (credentials) ->
      Promise.resolve
        config: credentials.enrichCredentials
          project_key: projectKey
          client_id: clientId
          client_secret: clientSecret

ensureCredentials(argv)
.then (credentials) ->
  clientOptions = _.extend credentials,
    timeout: argv.timeout
    user_agent: "#{package_json.name} - #{package_json.version}"
  clientOptions.host = argv.sphereHost if argv.sphereHost

  customerExport = new CustomerExport
    client: clientOptions
    export:
      where: argv.where
      csvTemplate: argv.csvTemplate || "#{__dirname}/../data/template-customer-simple.csv"

  ensureExportDir()
  .then (outputDir) =>
    logger.debug "Created output dir at #{outputDir}"
    @outputDir = outputDir
    customerExport.run()
  .then (data) =>

    @customerReferences = []
    ts = (new Date()).getTime()

    if argv.fileWithTimestamp
      fileName = "customers_#{ts}.csv"
    else
      fileName = 'customers.csv'

    csvFile = "#{@outputDir}/#{fileName}"
    logger.info "Storing CSV export to '#{csvFile}'."
    fs.writeFileAsync csvFile, data

  .then =>
    {sftpCredentials, sftpHost, sftpUsername, sftpPassword} = argv
    if sftpCredentials or (sftpHost and sftpUsername and sftpPassword)

      readJsonFromPath(sftpCredentials)
      .then (credentials) =>
        projectSftpCredentials = credentials[argv.projectKey] or {}
        {host, username, password, sftpTarget} = _.defaults projectSftpCredentials,
          host: sftpHost
          username: sftpUsername
          password: sftpPassword
          sftpTarget: argv.sftpTarget

        throw new Error 'Missing sftp host' unless host
        throw new Error 'Missing sftp username' unless username
        throw new Error 'Missing sftp password' unless password

        sftpClient = new Sftp
          host: host
          username: username
          password: password
          logger: logger

        sftpClient.openSftp()
        .then (sftp) =>
          fs.readdirAsync(@outputDir)
          .then (files) =>
            logger.info "About to upload #{_.size files} file(s) from #{@outputDir} to #{sftpTarget}"
            filesSkipped = 0
            Promise.map files, (filename) =>
              logger.debug "Uploading #{@outputDir}/#{filename}"
              sftpClient.safePutFile(sftp, "#{@outputDir}/#{filename}", "#{sftpTarget}/#{filename}")
              .then ->
                logger.debug "Upload of #{filename} successful."
              .catch (err) ->
                if argv.sftpContinueOnProblems
                  filesSkipped++
                  logger.warn err, "There was an error processing the file #{file}, skipping and continue"
                  Promise.resolve()
                else
                  Promise.reject err
            , {concurrency: 1}
            .then ->
              totFiles = _.size(files)
              if totFiles > 0
                logger.info "Export to SFTP successfully finished: #{totFiles - filesSkipped} out of #{totFiles} files were processed"
              else
                logger.info "Export successfully finished: there were no new files to be processed"
              sftpClient.close(sftp)
              Promise.resolve()
          .finally -> sftpClient.close(sftp)
        .catch (err) =>
          logger.error err, 'There was an error uploading the files to SFTP'
          @exitCode = 1
      .catch (err) =>
        logger.error err, "Problems on getting sftp credentials from config files for project #{argv.projectKey}."
        @exitCode = 1
    else
      Promise.resolve() # no sftp
  .then =>
    logger.info 'Customer export complete'
    @exitCode = 0
  .catch (error) =>
    logger.error error, 'Oops, something went wrong!'
    @exitCode = 1
  .done()
.catch (err) =>
  logger.error err, 'Problems on getting client credentials from config files.'
  @exitCode = 1
.done()
