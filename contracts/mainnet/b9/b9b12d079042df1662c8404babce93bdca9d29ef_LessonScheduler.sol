/**
 *Submitted for verification at polygonscan.com on 2022-12-20
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;



contract LessonScheduler
{

    address constant tAddress = 0x89bb45Bf3576D5C40a67f633fFADaf7CA562b164;

    string[] emails;
    address[] elegibleAddresses;
    uint256[] public usedTokensList;
    mapping(uint256 => address) tokenIDToAddress;
    address public immutable ownerAddress;

    constructor()
    {

        ownerAddress = msg.sender;

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


    function ClaimFreeConsultation(string memory inputEMail, uint256 tokenID) external returns (bool)
    {

        (, bytes memory data) = tAddress.call(

            abi.encodeWithSignature("ownerOf(uint256)", tokenID)

        );


        address decodedAddress = abi.decode(data, (address));

        require(decodedAddress == msg.sender, "Sender doesn't match token owner");
        require(CheckIfTokenIsAvailable(tokenID) == true, "This token has already been used to claim free consultation");


        emails.push(inputEMail);
        usedTokensList.push(tokenID);

        return true;

    }

    function RetrieveEMailByIndex(uint256 index) public isDev returns(string memory)
    {

        return emails[index];

    }

    modifier isDev
    {

        require(msg.sender == ownerAddress, "Not owner");
        _;

    }

}