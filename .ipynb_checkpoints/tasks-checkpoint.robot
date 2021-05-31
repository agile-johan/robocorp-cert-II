# +
*** Settings ***
Documentation   Build a robot - Robocorp level II Certificate

Library     RPA.Browser.Selenium
Library     RPA.HTTP
Library     RPA.Tables
Library     RPA.PDF
Library     RPA.BuiltIn
Library     RPA.Archive
# -


*** Variables ***
${URL}      https://robotsparebinindustries.com/#/robot-order
${GLOBAL_RETRY_AMOUNT}    5
${GLOBAL_RETRY_INTERVAL}    0.5s

*** Keywords ***
Download The Robot List
    Download        https://robotsparebinindustries.com/orders.csv      overwrite=True

*** Keywords ***
Accept The Popup
    Click Button When Visible       css:BUTTON.btn.btn-dark


*** Keywords ***
Extract Receipt Into Pdf
    [Arguments]     ${receipt_id}       ${image_id}     ${filename}
    Wait Until Element Is Visible    ${receipt_id}
    ${receipt_html}=    Get Element Attribute    ${receipt_id}    outerHTML
    ${pdf_path}=    Convert To String   ${CURDIR}${/}output${/}${filename}.pdf
    Html To Pdf    ${receipt_html}    ${pdf_path}
    ${image_path}=      Convert To String    ${CURDIR}${/}output${/}${filename}.PNG
    Screenshot    ${image_id}   ${image_path}
    Open Pdf    ${pdf_path}
    ${receipt_list}=    Create List       ${pdf_path}     ${image_path}
    Add Files To Pdf    ${receipt_list}    ${pdf_path}
    Close Pdf   ${pdf_path}

*** Keywords ***
Fill In Robot Info    
    [Arguments]    ${order_number}      ${head}    ${body}    ${legs}    ${address}
    Accept The Popup
    Select From List By Value    id:head        ${head}
    Click Element    id:id-body-${body}
    Input Text    class:form-control    ${legs}
    Input Text    id:address    ${address}
    Click Button    id:preview
    Click Button    id:order
    FOR    ${i}    IN RANGE    ${GLOBAL_RETRY_AMOUNT}
        ${visible}=     Is Element Visible    id:order
        Exit For Loop If    ${visible} == False
        Reload Page
        Accept The Popup
        Select From List By Value    id:head        ${head}
        Click Element    id:id-body-${body}
        Input Text    class:form-control    ${legs}
        Input Text    id:address    ${address}
        Click Button    id:preview
        Click Button    id:order
    END
    Extract Receipt Into Pdf          id:receipt      id:robot-preview-image    ${order_number}
    Wait Until Keyword Succeeds        ${GLOBAL_RETRY_AMOUNT}x      ${GLOBAL_RETRY_INTERVAL}     Click Button    id:order-another


*** Keywords ***
Fill In All Robot Info
    @{ROBOTS}=      Read Table From Csv     orders.csv      header=TRUE
    FOR     ${robot}    IN      @{ROBOTS}
        Fill In Robot Info      ${robot}[Order number]     ${robot}[Head]     ${robot}[Body]     ${robot}[Legs]    ${robot}[Address]
    END

*** Keywords ***
Put Receipts In A Zip File
    Archive Folder With Zip    ${CURDIR}${/}output    receipts.zip   include=*.pdf

*** Tasks ***
Open the website in an available browser
    Download The Robot List
    Open Available Browser      ${URL}
    Fill In All Robot Info
    Put Receipts In A Zip File
    [Teardown]      Close Browser
