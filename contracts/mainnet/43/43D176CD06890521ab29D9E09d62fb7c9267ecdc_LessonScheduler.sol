/**
 *Submitted for verification at polygonscan.com on 2022-12-15
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

contract LessonScheduler
{


    string[] emails;
    address[] public elegibleAddresses;
    uint256[] public usedTokensList;
    mapping(uint256 => address) tokenIDToAddress;

    constructor()
    {

        usedTokensList.push(4);

    }

    function CheckIfTokenIsAvailable(uint256 tokenIndex) payable public returns(bool)
    {

        if(usedTokensList.length == 0)
        {

            return true;
            

        }
        else
        {

            uint256 i = 1;

            for(i; i == usedTokensList.length; i++)
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

    function UpdateUsedTokensList(uint256 tokenID) public
    {

        usedTokensList.push(tokenID);

    }

    function WriteEMail(string memory inputEMail) public 
    {

        emails.push(inputEMail);

    }

    function RetrieveEMails() public view returns(string[] memory)
    {

        return emails;

    }


}