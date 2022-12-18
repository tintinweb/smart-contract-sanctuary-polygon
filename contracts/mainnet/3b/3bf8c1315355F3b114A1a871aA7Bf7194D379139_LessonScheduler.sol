/**
 *Submitted for verification at polygonscan.com on 2022-12-18
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

contract LessonScheduler
{

    struct Request{
        string eMail;
        uint256 tokenID;
        address userAddress;
        bool approved;
    }


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