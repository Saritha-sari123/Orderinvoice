CLASS lhc_item DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    METHODS setlineitemid FOR DETERMINE ON SAVE
      IMPORTING keys FOR item~setlineitemid.

ENDCLASS.

CLASS lhc_item IMPLEMENTATION.

  METHOD setlineitemid.
    DATA: max_lineitemid  TYPE zsa_item_id,
          lineitem        TYPE STRUCTURE FOR READ RESULT ZSA_INVOICE_ITEM_i,
          lineitem_update TYPE TABLE FOR UPDATE zbs_customer_I\\item.


    READ ENTITIES OF zbs_customer_I IN LOCAL MODE
    ENTITY item BY \_invoice
    FIELDS ( InvoiceUuid )
    WITH CORRESPONDING #( keys )
    RESULT DATA(invoices).


    READ ENTITIES OF zbs_customer_I IN LOCAL MODE
    ENTITY invoice BY \_item
    FIELDS ( InvoiceitemUuid )
    WITH CORRESPONDING #( invoices )
    LINK DATA(item_links)
    RESULT DATA(lineitems).

    LOOP AT invoices INTO DATA(invoice).

      "initlize the bookingsuppid number.
      max_lineitemid = '00'.
      LOOP AT item_links INTO DATA(item_link) USING KEY id WHERE source-%tky = invoice-%tky.

        lineitem = lineitems[ KEY id
                          %tky = item_link-target-%tky ].

        IF lineitem-LineItemId > max_lineitemid.
          max_lineitemid = lineitem-LineItemId.
        ENDIF.


      ENDLOOP.

      LOOP AT item_links INTO item_link USING KEY id WHERE source-%tky = invoice-%tky.

        lineitem = lineitems[ KEY id
                          %tky = item_link-target-%tky ].

        IF lineitem-LineItemId IS INITIAL.

          max_lineitemid += 1.

          APPEND VALUE #( %tky = lineitem-%tky
                         LineItemId =  max_lineitemid
                         ) TO lineitem_update.
        ENDIF.

      ENDLOOP.
    ENDLOOP.

    MODIFY ENTITIES OF zbs_customer_I IN LOCAL MODE
    ENTITY item
    UPDATE FIELDS ( LineItemId )
    WITH lineitem_update.


  ENDMETHOD.

ENDCLASS.

CLASS lhc_invoice DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    METHODS setinvoiceid FOR DETERMINE ON SAVE
      IMPORTING keys FOR invoice~setinvoiceid.

ENDCLASS.

CLASS lhc_invoice IMPLEMENTATION.

  METHOD setinvoiceid.

    DATA:max_invoiceid   TYPE zsa_invoice_id,
         invoice         TYPE STRUCTURE FOR READ RESULT zsa_invoice_i,
         invoices_update TYPE TABLE FOR UPDATE zbs_customer_i\\invoice.

    READ ENTITIES OF zbs_customer_I IN LOCAL MODE
    ENTITY invoice BY \_customer
    FIELDS ( CustomerUuid )
    WITH CORRESPONDING #( keys )
    RESULT DATA(customers).

    READ ENTITIES OF zbs_customer_I IN LOCAL MODE
    ENTITY customer BY \_invoice
    FIELDS ( InvoiceId )
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
                          invoiceId = max_invoiceid ) TO invoices_update.

        ENDIF.

      ENDLOOP.
    ENDLOOP.
    MODIFY ENTITIES OF zbs_customer_I IN LOCAL MODE
    ENTITY invoice
    UPDATE FIELDS ( InvoiceId )
    WITH invoices_update.





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
