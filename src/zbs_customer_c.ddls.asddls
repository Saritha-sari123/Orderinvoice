@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'consumption View for Customer'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
define root view entity ZBS_CUSTOMER_C
  provider contract transactional_query as projection on ZBS_CUSTOMER_I
{
    key CustomerUuid,
    CustomerId,
    FirstName,
    PhoneNumber,
    EmailAddress,
    LocalCreatedBy,
    LocalCreatedAt,
    LocalLastChangedBy,
    LocalLastChangedAt,
    LastChangedAt,
    /* Associations */
    _invoice:redirected to composition child ZSA_INVOICE_C
}
