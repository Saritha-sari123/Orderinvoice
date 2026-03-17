@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Item interface cds view'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZSA_INVOICE_ITEM_I
  as select from zsa_invoice_item
  association to parent ZSA_INVOICE_I as _invoice on $projection.InvoiceUuid = _invoice.InvoiceUuid
  association [1] to ZBS_CUSTOMER_I as _customer on $projection.CustomerUuid = _customer.CustomerUuid
{
  key invoiceitem_uuid      as InvoiceitemUuid,
      root_uuid             as CustomerUuid,
      parent_uuid           as InvoiceUuid,
      line_item_id          as LineItemId,
      invoice_id            as InvoiceId,
      product_id            as ProductId,
      @Semantics.quantity.unitOfMeasure: 'UnitField'
      quantity              as Quantity,
      unit_field            as UnitField,
      @Semantics.amount.currencyCode: 'CurrencyCode'
      price                 as Price,
      line_total as LineTotal,
      currency_code         as CurrencyCode,
      local_last_changed_at as LocalLastChangedAt,
      _invoice,
      _customer
}
