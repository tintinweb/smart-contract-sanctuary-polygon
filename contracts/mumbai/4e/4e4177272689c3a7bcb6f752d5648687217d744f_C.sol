/**
 *Submitted for verification at polygonscan.com on 2023-03-08
*/

pragma solidity 0.8.10;

library DataTypes {
        struct PostNoteData {
        uint256 characterId;
        string contentUri;
        address linkModule;
        bytes linkModuleInitData;
        address mintModule;
        bytes mintModuleInitData;
        bool locked;
    }
}

contract C {


   function postNote(
        DataTypes.PostNoteData calldata postNoteData
    ) external returns (uint256 noteId) {
        return 0;
    }
}