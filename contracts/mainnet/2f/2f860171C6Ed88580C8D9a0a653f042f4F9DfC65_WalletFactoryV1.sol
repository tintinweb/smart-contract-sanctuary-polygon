//SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

import "./CustomerWalletV1.sol";


interface WalletFactoryInterface{

    //Parent
    function CheckIfAdmin(address _adminAddress) external view returns(bool);
    function AddNewWallet(address _walletAddress, address _ownerAddress) external returns(bool);
    function GetFactoryAddress() external view returns(address);
    function CanCreateWallet(address _senderAddress) external view returns(bool);

    //Logger
    function LogIt(address _walletAddress, address _ownerAddress) external returns(bool);
}

contract WalletFactoryV1{

    address constant private fiskPayAddress = 0xaBE9255A99fd2EFB4a15fcF375E5D3987E32Ad74;
    WalletFactoryInterface constant private fisk = WalletFactoryInterface(fiskPayAddress);

    address constant private loggerAddress = 0xF70E41A9333FF85073A828c3C9d674AAF3A3A6F3;

    address private mixerAddress = address(0);

    uint256 private checkBlock = block.number;

    bool private isCreating = false;

    event WalletAddress(address _walletAddress);

    function CreateWalletContract() external returns(bool){

        require(!isCreating);
        require(fisk.GetFactoryAddress() == address(this), "Contract factory deprecated");
        require(fisk.CanCreateWallet(msg.sender), "You can mint a wallet approximately every 24 hours");
        require(mixerAddress != address(0), "Mixer not set");

        uint32 size;
        address sender = msg.sender;

        assembly {

            size := extcodesize(sender)
        }

        require(size == 0, "Contracts are not allowed to create wallets");

        CustomerWalletV1 newWalletContract = new CustomerWalletV1(fiskPayAddress);

        WalletFactoryInterface logger = WalletFactoryInterface(loggerAddress);

        isCreating = true;

        require((fisk.AddNewWallet(address(newWalletContract), msg.sender) && logger.LogIt(address(newWalletContract), msg.sender)), "Wallet could not be logged");

        isCreating = false;
        
        emit WalletAddress(address(newWalletContract));
        
        return true;
    }

    function SetMixerAddress(address _mixerAddress) external returns(bool){

        require(fisk.CheckIfAdmin(msg.sender), "Admin function only");
        require(_mixerAddress != mixerAddress, "Already set");

        require(checkBlock < block.number);
        checkBlock = block.number;

        mixerAddress = _mixerAddress;
        
        return true;
    }

    function GetMixerAddress() external view returns(address){

        return mixerAddress;
    }

    function FactoryVersion() external pure returns(string memory){
        
        return "v1.0";
    }

    receive() external payable{
        
        revert();
    }

    fallback() external payable{
        
        revert();
    }
}