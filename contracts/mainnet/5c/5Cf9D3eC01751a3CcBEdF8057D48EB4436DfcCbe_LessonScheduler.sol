/**
 *Submitted for verification at polygonscan.com on 2022-12-19
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;



contract LessonScheduler
{

    address constant tAddress = 0x89bb45Bf3576D5C40a67f633fFADaf7CA562b164;
    address constant storageAddress = 0x1e48764196B8aF0c35175C9dD996785F8dBb0858;
    //address constant storageAddress = 0xd9145CCE52D386f254917e481eB44e9943F39138;

    struct Request{
        string eMail;
        uint256 tokenID;
        address userAddress;
        bool approved;
    }

    uint256 public retrievedNumber = 0;
    uint256 numOfRequests = 0;
    Request[] requests;
    string[] emails;
    address[] elegibleAddresses;
    uint256[] public usedTokensList;
    mapping(uint256 => address) tokenIDToAddress;
    address immutable ownerAddress;

    constructor()
    {

        ownerAddress = msg.sender;
        elegibleAddresses.push(0xa8c7d5818A255A1856b31177E5c96E1D61c83991);

    }


    function TestStorageCall() public returns (bool, uint256)
    {

        (bool success, bytes memory data) = storageAddress.call
        (

            abi.encodeWithSignature("RetrieveNumber()")

        );

        uint256 decodedData = abi.decode(data, (uint256));
        retrievedNumber = decodedData;

        return (success, decodedData);
        
    }


    function RetrieveRequesters() public view returns(address[] memory)
    {

        return elegibleAddresses;

    }

    function CheckIfTokenIsAvailable(uint256 tokenIndex) public view returns(bool)
    {

        if(usedTokensList.length == 0)
        {

            return true;
            

        }
        else
        {

            uint256 i = 0;

            for(i; i < usedTokensList.length; i++)
            {

                if(tokenIndex == usedTokensList[i])
                {

                    return false;


                }

            }

            if (i <= usedTokensList.length)
            {

                return true;

            }

        }

        return false;
    }

    function CreateRequest(string memory inputEMail, address userAddres, uint256 tokenID) internal
    {

       requests.push(Request({eMail: inputEMail, tokenID: tokenID, userAddress: userAddres, approved: false}));
       elegibleAddresses.push(userAddres);
       numOfRequests++;

    }

    function GetNumberOfRequests() public view isDev returns(uint256)
    {

        return numOfRequests;

    }

    function GetRequestInfo(uint256 requestID) public view isDev returns(Request memory)
    {

        return requests[requestID];

    }

    function ApproveRequest(uint256 requestID) public isDev
    {

        Request memory tempRequest = requests[requestID];
        tempRequest.approved = true;
        emails.push(tempRequest.eMail);

    }

    function ClaimFreeConsultation(string memory inputEMail, uint256 tokenID) external 
    {

        CreateRequest(inputEMail, msg.sender, tokenID);
    }

    function RetrieveEMails() public view isDev returns(string[] memory)
    {

        return emails;

    }

    modifier isDev
    {

        require(msg.sender == ownerAddress, "Not owner");
        _;

    }

}