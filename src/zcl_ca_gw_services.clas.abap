CLASS zcl_ca_gw_services DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    CLASS-METHODS get_value_filter
      IMPORTING
        !iv_filter  TYPE any
        !io_request TYPE any
      EXPORTING
        !ev_value   TYPE any .
    CLASS-METHODS get_values_filter
      IMPORTING
        !iv_filter  TYPE any
        !io_request TYPE any
      EXPORTING
        !et_values  TYPE STANDARD TABLE.
    CLASS-METHODS get_value_key
      IMPORTING
        !iv_key     TYPE any
        !io_request TYPE any
      EXPORTING
        !ev_value   TYPE any .
    CLASS-METHODS get_language_filter
      IMPORTING
        !iv_filter      TYPE any OPTIONAL
        !io_request     TYPE any
      RETURNING
        VALUE(rv_spras) TYPE sylangu .
    CLASS-METHODS get_language_key
      IMPORTING
        iv_key          TYPE any OPTIONAL
        io_request      TYPE any
      RETURNING
        VALUE(rv_spras) TYPE sylangu .
    CLASS-METHODS launch_excep_msg_bapi
      IMPORTING
                io_context        TYPE REF TO /iwbep/if_mgw_context
                is_return         TYPE bapiret2
                iv_entity_name    TYPE string OPTIONAL
                iv_message_target TYPE string
      RAISING   /iwbep/cx_mgw_busi_exception.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_ca_gw_services IMPLEMENTATION.
  METHOD get_value_filter.
    CLEAR ev_value.

    DATA(lt_filter) = CAST /iwbep/cl_mgw_req_filter( CAST /iwbep/cl_mgw_request( io_request  )->/iwbep/if_mgw_req_entityset~get_filter( ) )->/iwbep/if_mgw_req_filter~get_filter_select_options( ).

    READ TABLE lt_filter ASSIGNING FIELD-SYMBOL(<ls_filter>) WITH KEY property = iv_filter.
    IF sy-subrc = 0.
      READ TABLE <ls_filter>-select_options ASSIGNING FIELD-SYMBOL(<ls_select_options>) INDEX 1.
      IF sy-subrc = 0.
        ev_value = <ls_select_options>-low.
      ENDIF.
    ENDIF.

  ENDMETHOD.

  METHOD get_value_key.

    CLEAR ev_value.

    DATA(lt_keys) = CAST /iwbep/cl_mgw_request( io_request )->/iwbep/if_mgw_req_entityset~get_source_keys( ).

    READ TABLE lt_keys ASSIGNING FIELD-SYMBOL(<ls_keys>) WITH KEY name = iv_key.
    IF sy-subrc = 0.
      ev_value = <ls_keys>-value.
    ENDIF.
  ENDMETHOD.

  METHOD get_language_filter.
    DATA lv_value TYPE c LENGTH 2.

    rv_spras = sy-langu. " Por defecto se devuelve el idioma de logon

    " Si no se pasa el filtro con el campo de idioma se asume que vendrá en el campo LANGU
    DATA(lv_filter) = COND string( WHEN iv_filter IS NOT INITIAL THEN iv_filter ELSE |LANGU| ).

    get_value_filter( EXPORTING iv_filter = lv_filter io_request = io_request IMPORTING ev_value = lv_value ).

    IF lv_value IS NOT INITIAL.
      CALL FUNCTION 'CONVERSION_EXIT_ISOLA_INPUT'
        EXPORTING
          input            = lv_value
        IMPORTING
          output           = rv_spras
        EXCEPTIONS
          unknown_language = 1
          OTHERS           = 2.
    ENDIF.

  ENDMETHOD.

  METHOD get_language_key.
    DATA lv_value TYPE c LENGTH 2.

    rv_spras = sy-langu. " Por defecto se devuelve el idioma de logon

    " Si no se pasa el filtro con el campo de idioma se asume que vendrá en el campo LANGU
    DATA(lv_filter) = COND string( WHEN iv_key IS NOT INITIAL THEN iv_key ELSE |LANGU| ).

    get_value_key( EXPORTING iv_key = lv_filter io_request = io_request IMPORTING ev_value = lv_value ).

    IF lv_value IS NOT INITIAL.
      CALL FUNCTION 'CONVERSION_EXIT_ISOLA_INPUT'
        EXPORTING
          input            = lv_value
        IMPORTING
          output           = rv_spras
        EXCEPTIONS
          unknown_language = 1
          OTHERS           = 2.
    ENDIF.
  ENDMETHOD.


  METHOD launch_excep_msg_bapi.
    DATA(lo_msg_container) = io_context->get_message_container( ).

    lo_msg_container->add_message_from_bapi(
      EXPORTING
        is_bapi_message           = is_return
        iv_entity_type            = iv_entity_name
        iv_message_target         = iv_message_target
        iv_add_to_response_header = abap_true ).

    RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
      EXPORTING
        message_container = lo_msg_container
        http_status_code  = /iwbep/cx_mgw_busi_exception=>gcs_http_status_codes-bad_request.
*       http_header_parameters =
  ENDMETHOD.

  METHOD get_values_filter.
    CLEAR et_values.

    DATA(lt_filter) = CAST /iwbep/cl_mgw_req_filter( CAST /iwbep/cl_mgw_request( io_request  )->/iwbep/if_mgw_req_entityset~get_filter( ) )->/iwbep/if_mgw_req_filter~get_filter_select_options( ).

    READ TABLE lt_filter ASSIGNING FIELD-SYMBOL(<ls_filter>) WITH KEY property = iv_filter.
    IF sy-subrc = 0.
      LOOP AT <ls_filter>-select_options ASSIGNING FIELD-SYMBOL(<ls_select_options>).
        APPEND INITIAL LINE TO et_values ASSIGNING FIELD-SYMBOL(<ls_value>).
        <ls_value> = <ls_select_options>-low.
      ENDLOOP.
    ENDIF.
  ENDMETHOD.

ENDCLASS.
