metadata name = 'Common interface types for custom modules'
metadata description = 'This module provides you with all common variants for custom interfaces to be used in modules.'
metadata owner = 'platform-engineers'

@export()
@description('Type definition for a end-to-end governance resource group.')
type governanceResourceGroupType = {
  @description('Required. The unique name of the resource group.')
  name: string

  @description('Optional. The location of the resource group.')
  location: string?

  @description('Optional. The tags of the resource group used as metadata.')
  tags: object?

  @description('Optional. The environment type of the resource group.')
  environmentType: ('sbx' | 'tst' | 'dev' | 'stg' | 'prd')?
}

@export()
@description('Type definition for a end-to-end governance security group.')
type governanceSecurityGroupType = {
  @description('Required. The display name of the security group.')
  displayName: string

  @description('Required. The unique name of the security group.')
  uniqueName: string

  @description('Required. The mail nickname of the security group.')
  mailNickname: string

  @description('Optional. The description of the security group.')
  description: string?

  @description('Optional. The environment type of the security group.')
  environmentType: ('sbx' | 'tst' | 'dev' | 'stg' | 'prd')?
}

@export()
@description('Type definition for a end-to-end governance managed identity.')
type governanceIdentityType = {
  @description('Required. The name of the managed identity.')
  name: string

  @description('Required. The resource group name of the managed identity.')
  resourceGroup: string

  @description('Optional. The location of the managed identity.')
  location: string?

  @description('Optional. The tags of the managed identity used as metadata.')
  tags: object?

  @description('Optional. The environment type of the managed identity.')
  environmentType: ('sbx' | 'tst' | 'dev' | 'stg' | 'prd')?
}
