_ = require 'underscore'
_.mixin require('underscore-mixins')
Promise = require 'bluebird'
fs = Promise.promisifyAll require('fs')
{SphereClient} = require 'sphere-node-sdk'
CsvMapping = require './mapping-utils/csv'

class CustomerExport

  constructor: (options = {}) ->
    @_exportOptions = _.defaults (options.export or {}),
      where: ''
    @client = new SphereClient options.client
    @csvMapping = new CsvMapping @_exportOptions

  run: ->
    @_fetchCustomers().then (customers) => @csvExport(customers)

  csvExport: (customers) ->
    throw new Error 'You need to provide a csv template for exporting customer information' unless @_exportOptions.csvTemplate
    fs.readFileAsync(@_exportOptions.csvTemplate, {encoding: 'utf-8'})
    .then (content) => @csvMapping.mapCustomers content, customers

  _fetchCustomers: ->
    customersQuery = @client.customers
    customersQuery.perPage(200)

    if @_exportOptions.where
      customersQuery.where(@_exportOptions.where)

    customersQuery
      .expand('customerGroup')
      .process (result) ->
        Promise.resolve(result.body.results)
      , { accumulate: true }


module.exports = CustomerExport
