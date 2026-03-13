@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'consumption View for Invoice item'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
define view entity ZSA_INVOICE_ITEM_C as projection on ZSA_INVOICE_ITEM_I
{
    key InvoiceitemUuid,
    CustomerUuid,
    InvoiceUuid,
    LineItemId,
    InvoiceId,
    ProductId,
    @Semantics.quantity.unitOfMeasure: 'UnitField'
    Quantity,
    UnitField,
    @Semantics.amount.currencyCode: 'CurrencyCode'
    Price,
    CurrencyCode,
    LocalLastChangedAt,
    /* Associations */
    _customer: redirected to ZBS_CUSTOMER_C,
    _invoice: redirected to parent ZSA_INVOICE_C
}
