CLASS lhc_item DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    METHODS setlineitemid FOR DETERMINE ON SAVE
      IMPORTING keys FOR item~setlineitemid.
    METHODS calculate_item_total FOR DETERMINE ON MODIFY
      IMPORTING keys FOR item~calculate_item_total.
    METHODS update_invoice_total FOR DETERMINE ON SAVE
      IMPORTING keys FOR item~update_invoice_total.

ENDCLASS.

CLASS lhc_item IMPLEMENTATION.



  METHOD setlineitemid.
    DATA: max_lineitemid  TYPE zsa_item_id,
          lineitem        TYPE STRUCTURE FOR READ RESULT ZSA_INVOICE_ITEM_i,
          lineitem_update TYPE TABLE FOR UPDATE zbs_customer_I\\item.

    " Corrected with single backslash

    " Read invoices for a particular customer

    READ ENTITIES OF zbs_customer_I IN LOCAL MODE
ENTITY item BY \_invoice
FIELDS ( InvoiceUuid )
WITH CORRESPONDING #( keys )
RESULT DATA(invoices).


    " Read items (line items) associated with invoices
    READ ENTITIES OF zbs_customer_I IN LOCAL MODE
    ENTITY invoice BY \_item
    FIELDS ( LineItemId InvoiceId )
    WITH CORRESPONDING #( invoices )
    LINK DATA(item_links)
    RESULT DATA(lineitems).

    LOOP AT invoices INTO DATA(invoice).

      " Initialize the max line item number
      max_lineitemid = '00'.

      " Determine the maximum LineItemId for the current invoice
      LOOP AT item_links INTO DATA(item_link) USING KEY id WHERE source-%tky = invoice-%tky.

        lineitem = lineitems[ KEY id
                            %tky = item_link-target-%tky ].

        IF lineitem-LineItemId > max_lineitemid.
          max_lineitemid = lineitem-LineItemId.
        ENDIF.

      ENDLOOP.

      " Loop again to process items that need an updated LineItemId and InvoiceId
      LOOP AT item_links INTO item_link USING KEY id WHERE source-%tky = invoice-%tky.

        lineitem = lineitems[ KEY id
                            %tky = item_link-target-%tky ].

        IF lineitem-LineItemId IS INITIAL.

          max_lineitemid += 1.

          " Append to the update table for line items
          APPEND VALUE #( %tky = lineitem-%tky
                         LineItemId = max_lineitemid
                         InvoiceId  = invoice-InvoiceId  " Corrected: Make sure InvoiceId is being updated, not InvoiceUuid
                         InvoiceUuid = invoice-InvoiceUuid " Optional: If you need to update InvoiceUuid as well
                         ) TO lineitem_update.

        ENDIF.

      ENDLOOP.

    ENDLOOP.

    " Modify the entities in RAP buffer with the updated LineItemId and InvoiceId
    MODIFY ENTITIES OF zbs_customer_i IN LOCAL MODE
      ENTITY item
      UPDATE FIELDS ( LineItemId InvoiceId )
      WITH lineitem_update.


*    DATA: max_lineitemid  TYPE zsa_item_id,
*          lineitem        TYPE STRUCTURE FOR READ RESULT ZSA_INVOICE_ITEM_i,
*          lineitem_update TYPE TABLE FOR UPDATE zbs_customer_I\\item.
*
*
*    READ ENTITIES OF zbs_customer_I IN LOCAL MODE
*    ENTITY item BY \_invoice
*    FIELDS ( InvoiceUuid )
*    WITH CORRESPONDING #( keys )
*    RESULT DATA(invoices).
*
*
*    READ ENTITIES OF zbs_customer_I IN LOCAL MODE
*    ENTITY invoice BY \_item
*    FIELDS ( LineItemId InvoiceId )
*    WITH CORRESPONDING #( invoices )
*    LINK DATA(item_links)
*    RESULT DATA(lineitems).
*
*    LOOP AT invoices INTO DATA(invoice).
*
*      "initlize the bookingsuppid number.
*      max_lineitemid = '00'.
*      LOOP AT item_links INTO DATA(item_link) USING KEY id WHERE source-%tky = invoice-%tky.
*
*        lineitem = lineitems[ KEY id
*                          %tky = item_link-target-%tky ].
*
*        IF lineitem-LineItemId > max_lineitemid.
*          max_lineitemid = lineitem-LineItemId.
*        ENDIF.
*
*      ENDLOOP.
*
*      LOOP AT item_links INTO item_link USING KEY id WHERE source-%tky = invoice-%tky.
*
*        lineitem = lineitems[ KEY id
*                          %tky = item_link-target-%tky ].
*
*        IF lineitem-LineItemId IS INITIAL.
*
*          max_lineitemid += 1.
*
*          APPEND VALUE #( %tky = lineitem-%tky
*                         LineItemId =  max_lineitemid
*                         InvoiceId  = invoice-InvoiceId
*                         ) TO lineitem_update.
*        ENDIF.
*
*      ENDLOOP.
*    ENDLOOP.
*
*    MODIFY ENTITIES OF zbs_customer_I IN LOCAL MODE
*    ENTITY item
*    UPDATE FIELDS ( LineItemId InvoiceId )
*    WITH lineitem_update.


  ENDMETHOD.

  METHOD calculate_item_total.
*  DATA lv_total TYPE p LENGTH 15 DECIMALS 2.
*  READ ENTITIES OF zbs_customer_I IN LOCAL MODE
*  ENTITY item
*  FIELDS ( Quantity Price )
*  WITH CORRESPONDING #( keys )
*  RESULT DATA(lt_items).
*
*LOOP AT lt_items INTO DATA(ls_item).
*
*  lv_total = ls_item-Quantity * ls_item-Price.
*
*  MODIFY ENTITIES OF zbs_customer_I IN LOCAL MODE
*    ENTITY item
*    UPDATE
*    FIELDS ( Price )
*    WITH VALUE #( (
*        %tky = ls_item-%tky
*        Price = lv_total
*    ) ).
*
*ENDLOOP.

    READ ENTITIES OF zbs_customer_I IN LOCAL MODE
      ENTITY item
      FIELDS ( Quantity Price )
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_items).

    MODIFY ENTITIES OF zbs_customer_I IN LOCAL MODE
      ENTITY item
      UPDATE FIELDS ( LineTotal )
      WITH VALUE #(
        FOR ls_item IN lt_items
        (
          %tky      = ls_item-%tky
          LineTotal = ls_item-Quantity * ls_item-Price
        )
      ).
  ENDMETHOD.

  METHOD update_invoice_total.
    TYPES: BEGIN OF ty_inv_key,
             InvoiceUuid TYPE zsa_invoice-invoice_uuid,
           END OF ty_inv_key.

    DATA: lt_invoice_keys TYPE STANDARD TABLE OF ty_inv_key.
    " Step 1: Get affected invoices
    READ ENTITIES OF zbs_customer_I IN LOCAL MODE
      ENTITY item
      FIELDS ( InvoiceUuid )
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_items).

    lt_invoice_keys = VALUE #(
      FOR ls_item IN lt_items
        ( InvoiceUuid = ls_item-InvoiceUuid )
    ).

    DELETE ADJACENT DUPLICATES FROM lt_invoice_keys.

    LOOP AT lt_invoice_keys INTO DATA(ls_inv).

      " Step 2: Read all items of this invoice
      READ ENTITIES OF zbs_customer_I IN LOCAL MODE
        ENTITY invoice BY \_item
        FIELDS ( LineTotal )
        WITH VALUE #(
          ( InvoiceUuid = ls_inv-InvoiceUuid )
        )
        RESULT DATA(lt_all_items).

      " Step 3: Calculate sum
      DATA(lv_total) = REDUCE #(
        INIT x = 0
        FOR ls IN lt_all_items
        NEXT x = x + ls-LineTotal ).

      " Step 4: Update invoice
      MODIFY ENTITIES OF zbs_customer_I IN LOCAL MODE
        ENTITY invoice
        UPDATE FIELDS ( TotalAmount )
        WITH VALUE #(
          ( InvoiceUuid = ls_inv-InvoiceUuid
            TotalAmount = lv_total )
        ).

    ENDLOOP.

  ENDMETHOD.

ENDCLASS.

CLASS lhc_invoice DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    METHODS setinvoiceid FOR DETERMINE ON SAVE
      IMPORTING keys FOR invoice~setinvoiceid.
    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR invoice RESULT result.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR invoice RESULT result.

    METHODS paid FOR MODIFY
      IMPORTING keys FOR ACTION invoice~paid RESULT result.

    METHODS unpaid FOR MODIFY
      IMPORTING keys FOR ACTION invoice~unpaid RESULT result.

ENDCLASS.

CLASS lhc_invoice IMPLEMENTATION.

  METHOD setinvoiceid.

    DATA:max_invoiceid   TYPE zsa_invoice_id,
         invoice         TYPE STRUCTURE FOR READ RESULT zsa_invoice_i,
         invoices_update TYPE TABLE FOR UPDATE zbs_customer_i\\invoice.

    READ ENTITIES OF zbs_customer_I IN LOCAL MODE
    ENTITY invoice BY \_customer
    FIELDS ( CustomerUuid CustomerId )
    WITH CORRESPONDING #( keys )
    RESULT DATA(customers).

    READ ENTITIES OF zbs_customer_I IN LOCAL MODE
    ENTITY customer BY \_invoice
    FIELDS ( InvoiceId CustomerId )
    WITH CORRESPONDING #( customers )
    LINK DATA(invoicelinks)
    RESULT DATA(invoices).

    LOOP AT customers INTO DATA(customer).

      max_invoiceid = '0000'.
      LOOP AT invoicelinks INTO DATA(invoice_link) USING KEY id WHERE source-%tky = customer-%tky.

        invoice = invoices[ KEY id
                            %tky = invoice_link-target-%tky ].

        IF invoice-InvoiceId > max_invoiceid.
          max_invoiceid = invoice-InvoiceId.
        ENDIF.

      ENDLOOP.

      LOOP AT invoicelinks INTO invoice_link USING KEY id WHERE source-%tky = customer-%tky.

        invoice = invoices[ KEY id
                                    %tky = invoice_link-target-%tky ].

        IF  invoice-InvoiceId IS INITIAL.
          max_invoiceid += 1.
          APPEND VALUE #( %tky = invoice-%tky
                          invoiceId = max_invoiceid
                          CustomerId = customer-CustomerId
                           ) TO invoices_update.

        ENDIF.

      ENDLOOP.
    ENDLOOP.
    MODIFY ENTITIES OF zbs_customer_I IN LOCAL MODE
    ENTITY invoice
    UPDATE FIELDS ( InvoiceId CustomerId )
    WITH invoices_update.





  ENDMETHOD.

  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD get_global_authorizations.
  ENDMETHOD.

  METHOD Paid.
*    MODIFY ENTITIES OF zbs_customer_I IN LOCAL MODE
*    ENTITY invoice
*    UPDATE FIELDS ( Status )
*    WITH VALUE #( FOR Key IN keys ( %tky = key-%tky
*                                    Status = 'P' ) ).
*
*    READ ENTITIES OF zbs_customer_I IN LOCAL MODE
*    ENTITY invoice
*    ALL FIELDS WITH CORRESPONDING #( keys )
*    RESULT DATA(invoices).
*
*    resUlt = VALUE #( FOR invoice IN invoices ( %tky = invoice-%tky
*                                                %param = invoice ) ).


  ENDMETHOD.

  METHOD unpaid.
  ENDMETHOD.

ENDCLASS.

CLASS lhc_customer DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR customer RESULT result.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR customer RESULT result.
    METHODS set_customerid FOR DETERMINE ON SAVE
      IMPORTING keys FOR customer~set_customerid.

ENDCLASS.

CLASS lhc_customer IMPLEMENTATION.

  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD get_global_authorizations.
  ENDMETHOD.

  METHOD set_customerid.
    READ ENTITIES OF zbs_customer_i IN LOCAL MODE
    ENTITY customer
    FIELDS ( CustomerId  )
    WITH CORRESPONDING #( keys )
    RESULT DATA(lt_customer).

    DELETE lt_customer WHERE CustomerId IS NOT INITIAL.

    SELECT SINGLE FROM zbs_customer FIELDS MAX( customer_id ) INTO @DATA(lv_customerid_max).

    MODIFY ENTITIES OF zbs_customer_i IN LOCAL MODE
    ENTITY customer
    UPDATE FIELDS ( CustomerId )
    WITH VALUE #( FOR ls_customer_id IN lt_customer INDEX INTO lv_index
                   ( %tky = ls_customer_id-%tky
                   CustomerId = lv_customerid_max + lv_index
                   ) ).

  ENDMETHOD.

ENDCLASS.
