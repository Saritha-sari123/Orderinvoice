@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'consumption View for Customer'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
@VDM.viewType: #CONSUMPTION
define root view entity ZBS_CUSTOMER_C
  provider contract transactional_query as projection on ZBS_CUSTOMER_I
{
    key CustomerUuid,
    CustomerId,
    FirstName,
    PhoneNumber1,
    EmailAddress1,
    LocalCreatedBy,
    LocalCreatedAt,
    LocalLastChangedBy,
    LocalLastChangedAt,
    LastChangedAt,
    _Customer.PhoneNumber as PhoneNumber,
    _Customer.EMailAddress as EmailAddress,
    /* Associations */
    _invoice:redirected to composition child ZSA_INVOICE_C
}
