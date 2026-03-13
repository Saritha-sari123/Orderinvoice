@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'consumption View for Invoice'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
define view entity ZSA_INVOICE_C as projection on ZSA_INVOICE_I
{
    key InvoiceUuid,
    CustomerUuid,
    InvoiceId,
    CustomerId,
    InvoiceDate,
    DueDate,
    @Semantics.amount.currencyCode: 'CurrencyCode'
    TotalAmount,
    CurrencyCode,
    Status,
    LocalLastChangedAt,
    /* Associations */
    _customer: redirected to parent ZBS_CUSTOMER_C,
    _item: redirected to composition child ZSA_INVOICE_ITEM_C
}
