metadata name = 'Common functions'
metadata description = 'This module provides you with some user-defined functions to be used in modules.'
metadata owner = 'project-administrators'

// cSpell:disable

@export()
@description('Returns the code for allowed locations that can be used as resource suffix.')
@metadata({
  example: 'getLocationCode(\'westeurope\')'
  input: 'The Azure location name e.g.: westeurope'
})
func getLocationCode(location string) string =>
  {
    centralus: 'cus'
    eastus: 'eus'
    eastus2: 'eus2'
    francecentral: 'frc'
    francesouth: 'frs'
    germanynorth: 'gn'
    germanywestcentral: 'gwc'
    italynorth: 'itn'
    northcentralus: 'ncus'
    northeurope: 'neu'
    norwayeast: 'nwe'
    norwaywest: 'nww'
    polandcentral: 'plc'
    spaincentral: 'spc'
    swedencentral: 'sdc'
    swedensouth: 'sds'
    switzerlandnorth: 'szn'
    switzerlandwest: 'szw'
    westcentralus: 'wcus'
    westeurope: 'weu'
    westus: 'wus'
    westus2: 'wus2'
    westus3: 'wus3'
  }[location]
