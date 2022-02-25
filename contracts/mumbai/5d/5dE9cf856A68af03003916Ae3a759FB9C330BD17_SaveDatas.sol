/**
 *Submitted for verification at polygonscan.com on 2022-02-24
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

/*
@whyCreated : 
This contract was created to record your information.
Of course, with the difference that you create a password when you deploy the contract
You must enter that password when you want to use your contract.
If the password matched the password given at the time of the contract deploy you can
Services showed the owners, show Datas and add Datas
*/

contract SaveDatas{

    //Password contract
    uint private pass;

    //Password entered by the user
    uint private yourPass;

    //save Datas
    bytes32 [] private DATA;

    //save address owners
    address [] private owners;

    modifier onlyOwns
    ()
    {
        require (yourPass==pass);
        _;
    }

    //create password of the contract
    constructor
    (uint _pass)
    {
        pass = _pass;
    }

    //The password that the user enters 
    //If it matches the contact password, the user's address will be saved as the owners
    function accessing
    (uint YourPass)
    public 
    returns(bool success)
    {
        yourPass = YourPass;
        require (YourPass==pass);
        owners.push(msg.sender);
        return true;
    }

    //If the necessary access is given to the user, the user can enter and save new data
    function addData
        (bytes32 newData)
    public onlyOwns
    returns(bool success)
    {
        DATA.push(newData);
        return true;
    }

    //If the necessary access is given to the user, The user can delete data
    function deleteDatas
    (uint index)
    public onlyOwns
    returns(bool success)
    {
        delete DATA[index];
        return true;
    }

    //If the necessary access is given to the user, the user can Show Datas
    function ShowDATAs
    ()
    public view onlyOwns 
        returns(bytes32 [] memory)
    {
        return DATA;
    }

    //If the necessary access is given to the user, the user van show Owners
    function showOwners
    ()
    public view onlyOwns 
        returns(address [] memory)
    {
        return owners;
    }
}