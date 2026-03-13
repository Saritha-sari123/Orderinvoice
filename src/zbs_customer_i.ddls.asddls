@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'interfacecdsviewfor customer root entity'
@Metadata.ignorePropagatedAnnotations: true
define root view entity ZBS_CUSTOMER_I as select from ZBS_CUSTOMER
composition [0..*] of ZSA_INVOICE_I as _invoice
{
    key customer_uuid as CustomerUuid,
    customer_id as CustomerId,
    first_name as FirstName,
    phone_number as PhoneNumber,
    email_address as EmailAddress,
    local_created_by as LocalCreatedBy,
    local_created_at as LocalCreatedAt,
    local_last_changed_by as LocalLastChangedBy,
    local_last_changed_at as LocalLastChangedAt,
    last_changed_at as LastChangedAt,
    _invoice
}
