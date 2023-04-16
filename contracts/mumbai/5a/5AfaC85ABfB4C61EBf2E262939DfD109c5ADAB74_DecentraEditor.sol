// SPDX-License-Identifier: UNLICENSED



pragma solidity ^0.8.0;

contract DecentraEditor {

    // Struct representing document
    struct Document{
        bytes content;
        address[] editors;
        mapping (address=>bool) hasAccess;
    }

    // Document Id mapping of the documents;
    mapping(bytes32 => Document) documents;

    // event For Prompt, whenever a new doc is created
    event DocumentCreated(bytes32 documentId, address creator);

    // Creating a new Document
    function createDocument (bytes32 documentId, bytes memory content) public{

        // To make sure, that documentId is not already in use 
        require(documents[documentId].content.length==0, "Document Already Exists, Try with other name");

        // Adding creator as an editor [with full access]
        Document storage document = documents[documentId];
            document.content = content;
            // giving editor access
            document.editors.push(msg.sender);
            document.hasAccess[msg.sender] = true;

            // Prompt : Document created
            emit DocumentCreated(documentId, msg.sender);
    }

    // Giving Editors Access to a Document
    function addEditor(bytes32 documentId, address editor) public{

        // check condition if already added or not
        Document storage document = documents[documentId];
        require(!document.hasAccess[editor], "Editor already has access");

        // Adding editor
        document.editors.push(editor);
        document.hasAccess[editor] = true;
    }

    // Function for revoking edit access from the document
    function removeEditor(bytes32 documentId, address editor) public {

        // check condition: editor has already been added
        Document storage document = documents[documentId];
        require(document.hasAccess[editor], "Editor Does not have access, No need to revoke");

        // Revoking Access
        uint256 editorIndex;
        for(uint256 i=0; i<document.editors.length; i++){
            if (document.editors[i] == editor){
                editorIndex = i;
                break;
            }
        }
        for(uint256 i= editorIndex; i<document.editors.length-1; i++){
            document.editors[i] = document.editors[i+1];
        }
            document.editors.pop();
            document.hasAccess[editor] = false;
    }

    // For updating content of the document
    function updateContent(bytes32 documentId, bytes memory content) public{

        // Verifying if the Editor has access to edit the document or not
        Document storage document = documents[documentId];
        require(document.hasAccess[msg.sender], "Sender does not have access");

        // Updating content
        document.content = content;
    }

    function getContent(bytes32 documentId) public view returns (bytes memory){
        
        // Ensure that sender has access to view the document
        Document storage document = documents[documentId];
        require(document.hasAccess[msg.sender], "Sender does not have access to view this file");

        // Return the content
        return document.content;
    }

    function getEditors(bytes32 documentId) public view returns (address[] memory){
        
        // condition check: sender is the Owner of the document
        Document storage document = documents[documentId];
        require(document.hasAccess[msg.sender], "You are not the owner of the document");


        return document.editors;
    }

}