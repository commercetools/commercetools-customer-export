![commercetools icon](http://www.commercetools.com/assets/img/orange-logo-horizontal-300wd.png)

# Customer export


[![Build Status](https://secure.travis-ci.org/mmoelli/commercetools-customer-export.png?branch=master)](http://travis-ci.org/mmoelli/commercetools-customer-export) [![NPM version](https://badge.fury.io/js/commercetools-customer-export.png)](http://badge.fury.io/js/commercetools-customer-export) [![Coverage Status](https://coveralls.io/repos/mmoelli/commercetools-customer-export/badge.png)](https://coveralls.io/r/mmoelli/commercetools-customer-export) [![Dependency Status](https://david-dm.org/mmoelli/commercetools-customer-export.png?theme=shields.io)](https://david-dm.org/mmoelli/commercetools-customer-export) [![devDependency Status](https://david-dm.org/mmoelli/commercetools-customer-export/dev-status.png?theme=shields.io)](https://david-dm.org/mmoelli/commercetools-customer-export#info=devDependencies)

This module allows to export customers to CSV, with SFTP support.

## Getting started

```bash
$ npm install -g commercetools-customer-export

# output help screen
$ customer-export
```

### SFTP
Exported customer can be automatically uploaded to an SFTP server.

When using SFTP you need to provide at least the required `--sftp*` options:
- `--sftpCredentials` (or `--sftpHost`, `--sftpUsername`, `--sftpPassword`)
- `--sftpSource`
- `--sftpTarget`

### CSV Format
Customers exported in CSV are stored in a single file

> At the moment you need to provide a `--csvTemplate` with headers in order to export related fields (see [examples](data)).

```csv
id,customerNumber
```

The following headers can be used in the CSV template
- `id`
- `customerNumber`
- `externalId`
- `firstName`
- `middleName`
- `lastName`
- `email`
- `dateOfbirth`
- `companyName`
- `vatId`
- `defaultShippingAddressId`
- `defaultBillingAddressId`
- `customerGroup`
- `isEmailVerified`
- `addressed.*` - eg. `id`, `streetName` or `additionalStreetInfo`

In general you can get access to any property of the customer object. Find a reference in our [API documentation](http://dev.sphere.io/http-api-projects-customers.html#customer).

> Note that when at least one `addresses` header is given the resulting CSV contains a row per address. Otherwise it only contains one row per customer.


## Contributing
In lieu of a formal styleguide, take care to maintain the existing coding style. Add unit tests for any new or changed functionality. Lint and test your code using [Grunt](http://gruntjs.com/).
More info [here](CONTRIBUTING.md)

## Releasing
Releasing a new version is completely automated using the Grunt task `grunt release`.

```javascript
grunt release // patch release
grunt release:minor // minor release
grunt release:major // major release
```

## License
Copyright (c) 2015 commercetools
Licensed under the [MIT license](LICENSE-MIT).
