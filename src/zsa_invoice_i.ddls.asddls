@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Invoice interface cds view'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZSA_INVOICE_I
  as select from ZSA_INVOICE
  composition [0..*] of ZSA_INVOICE_ITEM_I as _item
  association to parent ZBS_CUSTOMER_I     as _customer on $projection.CustomerUuid = _customer.CustomerUuid
{
  key invoice_uuid          as InvoiceUuid,
      parent_uuid           as CustomerUuid,
      invoice_id            as InvoiceId,
      customer_id           as CustomerId,
      invoice_date          as InvoiceDate,
      due_date              as DueDate,
      @Semantics.amount.currencyCode: 'CurrencyCode'
      total_amount          as TotalAmount,
      currency_code         as CurrencyCode,
      status                as Status,
      local_last_changed_at as LocalLastChangedAt,
      _item,
      _customer
}
