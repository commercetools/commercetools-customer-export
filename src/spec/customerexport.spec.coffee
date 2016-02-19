_ = require 'underscore'
_.mixin require('underscore-mixins')
Promise = require 'bluebird'
CustomerExport = require '../lib/customerexport'
Config = require '../config'
customersJson = require '../data/customers.json'


describe 'CustomerExport', ->

  beforeEach ->
    @customerExport = new CustomerExport client: Config
    expect(@customerExport._exportOptions).toEqual
      fetchHours: 48

  #it '#run', -> # TODO

  xit 'should throw an error if no csvTemplate was given', (done) ->
    @customerExport._exportOptions.csvTemplate = null

    errors = @customerExport.csvExport(customersJson)
    expect(errors.length).toBe 1
    expect(errors[0]).toEqual 'You need to provide a csv template for exporting customer information'

  it '#_fetchCustomers (all)', (done) ->
    spyOn(@customerExport.client.customers, 'fetch').andCallFake -> Promise.resolve
      body:
        results: [1, 2]
    @customerExport._fetchCustomers()
    .then (customers) ->
      expect(customers).toEqual [1, 2]
      done()
    .catch (e) -> done e
