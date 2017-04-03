_ = require 'underscore'
_.mixin require('underscore-mixins')
Promise = require 'bluebird'
CustomerExport = require '../lib/customerexport'
customersJson = require '../data/customers.json'


describe 'CustomerExport', ->

  beforeEach ->
    config = config:
      project_key: 'test'
      client_secret: 'test'
      client_id: 'test'
    @customerExport = new CustomerExport client: config
    expect(@customerExport._exportOptions).toEqual
      where: ''

  it 'should throw an error if no csvTemplate was given', ->
    @customerExport._exportOptions.csvTemplate = null

    csvExport = => @customerExport.csvExport(customersJson)
    expect(csvExport).toThrow(new Error 'You need to provide a csv template for exporting customer information')

  it '#_fetchCustomers (all)', (done) ->
    spyOn(@customerExport.client.customers, 'all')
    spyOn(@customerExport.client.customers, 'fetch').andCallFake -> Promise.resolve
      body:
        results: [1, 2]
    @customerExport._fetchCustomers()
    .then (customers) =>
      expect(customers).toEqual [1, 2]
      expect(@customerExport.client.customers.all).toHaveBeenCalled()
      done()
    .catch (e) -> done e

  it '#_fetchCustomers with predicate', (done) ->
    config =
      client:
        config:
          project_key: 'test'
          client_secret: 'test'
          client_id: 'test'
      export:
        where: 'abcd'

    customerExport = new CustomerExport config

    spyOn(customerExport.client.customers, 'where')
    spyOn(customerExport.client.customers, 'fetch').andCallFake -> Promise.resolve
      body:
        results: [1, 2]

    customerExport._fetchCustomers()
    .then (customers) ->
      expect(customers).toEqual [1, 2]
      expect(customerExport.client.customers.where).toHaveBeenCalledWith('abcd')
      done()
    .catch (e) -> done e
