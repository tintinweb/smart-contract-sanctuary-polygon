/**
 *Submitted for verification at polygonscan.com on 2022-12-11
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

contract LessonScheduler
{

    address constant TContractAddress = 0x89bb45Bf3576D5C40a67f633fFADaf7CA562b164;

    string[] emails;
    uint256[] public usedTokensList;
    mapping(uint256 => address) tokenIDToAddress;

    function CheckIfTokenIsAvailable(uint256 tokenIndex) public returns(bool)
    {

        if(usedTokensList.length == 0)
        {

            usedTokensList.push(tokenIndex);
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

                usedTokensList.push(tokenIndex);
                return true;

            }

        }


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