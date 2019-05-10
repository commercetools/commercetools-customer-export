_ = require 'underscore'
_.mixin require('underscore-mixins')
CsvMapping = require '../../lib/mapping-utils/csv'
customersJson = require '../../data/customers.json'

describe 'Mapping utils - CSV', ->

  beforeEach ->
    @csvMapping = new CsvMapping()

  describe '#mapCustomers', ->

    it 'should export base attributes', (done) ->
      template =
        """
        id,customerNumber
        """

      expectedCSV =
        """
        id,customerNumber
        651ba345-67c8-40b0-8bab-1dd3e39a60b1,6967166
        f19a1c5a-6741-40cb-9c8a-b7c708e581b2,6176221
        f6ca9f22-9e66-48f5-ba94-ef898a0214d6,1959447
        495fb34a-cc81-4c5e-90a4-96e277412375,6334179
        28f94f5c-3412-4707-8fae-d63e3cc983fb,6050365
        
        """

      @csvMapping.mapCustomers(template, customersJson)
      .then (result) ->
        expect(result).toBe expectedCSV
        done()
      .catch (err) -> done(_.prettify err)
      .done()

    it 'export addresses', (done) ->
      template =
        """
        id,customerNumber,addresses.firstName
        """

      expectedCSV =
        """
        id,customerNumber,addresses.firstName
        651ba345-67c8-40b0-8bab-1dd3e39a60b1,6967166,
        651ba345-67c8-40b0-8bab-1dd3e39a60b1,6967166,Léa
        651ba345-67c8-40b0-8bab-1dd3e39a60b1,6967166,Thérèsa
        651ba345-67c8-40b0-8bab-1dd3e39a60b1,6967166,Mélissandre
        651ba345-67c8-40b0-8bab-1dd3e39a60b1,6967166,Kévina
        651ba345-67c8-40b0-8bab-1dd3e39a60b1,6967166,Vérane
        f19a1c5a-6741-40cb-9c8a-b7c708e581b2,6176221,
        f19a1c5a-6741-40cb-9c8a-b7c708e581b2,6176221,Gérald
        f19a1c5a-6741-40cb-9c8a-b7c708e581b2,6176221,Marylène
        f19a1c5a-6741-40cb-9c8a-b7c708e581b2,6176221,Léone
        f19a1c5a-6741-40cb-9c8a-b7c708e581b2,6176221,Cécile
        f19a1c5a-6741-40cb-9c8a-b7c708e581b2,6176221,Ruì
        f6ca9f22-9e66-48f5-ba94-ef898a0214d6,1959447,
        f6ca9f22-9e66-48f5-ba94-ef898a0214d6,1959447,Torbjörn
        f6ca9f22-9e66-48f5-ba94-ef898a0214d6,1959447,Eugénie
        495fb34a-cc81-4c5e-90a4-96e277412375,6334179,
        495fb34a-cc81-4c5e-90a4-96e277412375,6334179,Bécassine
        28f94f5c-3412-4707-8fae-d63e3cc983fb,6050365,
        28f94f5c-3412-4707-8fae-d63e3cc983fb,6050365,Bénédicte
        28f94f5c-3412-4707-8fae-d63e3cc983fb,6050365,Håkan
        28f94f5c-3412-4707-8fae-d63e3cc983fb,6050365,Lyséa
        
        """

      @csvMapping.mapCustomers(template, customersJson)
      .then (result) ->
        expect(result).toBe expectedCSV
        done()
      .catch (err) -> done(_.prettify err)
      .done()

    it 'export customer groups', (done) ->
      template =
        """
        id,customerNumber,customerGroup
        """

      expectedCSV =
        """
        id,customerNumber,customerGroup
        651ba345-67c8-40b0-8bab-1dd3e39a60b1,6967166,group 1
        f19a1c5a-6741-40cb-9c8a-b7c708e581b2,6176221,group 2
        f6ca9f22-9e66-48f5-ba94-ef898a0214d6,1959447,group 3
        495fb34a-cc81-4c5e-90a4-96e277412375,6334179,group 4
        28f94f5c-3412-4707-8fae-d63e3cc983fb,6050365,group 5
        
        """

      @csvMapping.mapCustomers(template, customersJson)
      .then (result) ->
        expect(result).toBe expectedCSV
        done()
      .catch (err) -> done(_.prettify err)
      .done()

  xdescribe '#format*', -> # TODO

  xdescribe '#parse', -> # TODO

  xdescribe '#toCSV', -> # TODO
