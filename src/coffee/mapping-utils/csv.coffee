_ = require 'underscore'
Promise = require 'bluebird'
Csv = require 'csv'
access = require 'safe-access'

class CsvMapping

  COLUMNS_FOR_ALL_ROWS = [
    'id'
    'customerNumber'
  ]

  mapCustomers: (template, customers) ->
    @_analyseTemplate(template)
    .then ([header, mappings]) =>
      rows = _.map customers, (customer) =>
        @_mapCustomer(customer, mappings)

      data = _.flatten rows, true
      @toCSV(header, data)

  _mapCustomer: (customer, mappings) ->
    rows = []
    rows.push _.map mappings, (mapping) =>
      @_getValue customer, mapping

    if customer.addresses? and @hasAddressHeader?
      _.each customer.addresses, (address, index) =>
        rows.push _.map mappings, (mapping) =>
          if /addresses/.test(mapping)
            addressMapping = [mapping[0].replace(/addresses/, "addresses[#{index}]"), mapping[1]]
            @_getValue customer, addressMapping
          else if _.contains COLUMNS_FOR_ALL_ROWS, mapping[0]
            @_getValue customer, mapping

    rows

  _getValue: (customer, mapping) ->
    value = access customer, mapping[0]
    return '' unless value
    if _.size(mapping) is 2 and _.isFunction mapping[1]
      mapping[1].call undefined, value
    else
      value or ''

  _analyseTemplate: (template) ->
    @parse(template)
    .then (header) =>
      mappings = _.map header, (entry) =>
        if /addresses/.test entry
          @hasAddressHeader = true
        @_mapHeader(entry)
      Promise.resolve [header, mappings]

  _mapHeader: (entry) ->
    switch entry
      when 'customerGroup' then [entry, formatCustomerGroup]
      else [entry]


  formatCustomerGroup = (customerGroup) ->
    if customerGroup?
      "#{customerGroup.obj.name}"

  parse: (csvString) ->
    new Promise (resolve, reject) ->
      Csv.parse(csvString)
      .on 'error', (error) -> reject error
      .on 'readable', () ->
        data = @read()
        resolve data

  toCSV: (header, data) ->
    new Promise (resolve, reject) ->
      Csv.stringify(
        data,
        {header:true, columns: header},
        (err, output) ->
          return reject err if err
          resolve output
      )

module.exports = CsvMapping
