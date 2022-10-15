/**
 *Submitted for verification at polygonscan.com on 2022-10-13
*/

//SPDX-License-Identifier: MIT

pragma solidity 0.8.11;


interface FiskPayCustomerInterface{

    //Admin
    function CheckIfAdmin(address _adminAddress) external view returns(bool);

    //Tokens
    function ViewToken(uint8 _tokenIndex) external view returns(address);
    function CheckIfTokenEnabled(address _tokenAddress) external view returns(bool);
    function CountTokens() external view returns(uint8);

    //ERC20 Token Interface
    function symbol() external pure returns (string memory);
    function balanceOf(address _tokenOwner) external view returns (uint256);
    function allowance(address _owner, address _delegate) external view returns (uint256);

    function approve(address _delegateAddress, uint256 _tokenAmount) external returns(bool);
    function transfer(address _receiverAddress, uint256 _tokenAmount) external returns(bool);
    function transferFrom(address _ownerAddress, address _receiverAddress, uint256 _tokenAmount) external returns(bool);

    //FiskPay Wallet
    function GetFiskPayWalletAddress() external view returns(address);

    //Customer Wallets
    function GetWalletContractOwner(address _walletAddress) external view returns(address);

    //FiskPay Switch
    function GetPaymentState() external view returns(bool);

}

contract CustomerWalletV1dot1{

    address immutable private fiskPayAddress;
    FiskPayCustomerInterface immutable private fisk;

    address constant private fiskPaySwitch = 0x73594537Ad42661F56a53975736006d8a7343F66;
    FiskPayCustomerInterface constant private sw = FiskPayCustomerInterface(fiskPaySwitch);

    uint256 private totalCoins = 0;
    uint256 private currentCoins = 0;
    mapping(address => uint256) private totalEarnings;
    mapping(address => uint256) private currentEarnings;

    bool private adminUnlocked = false;
    uint256 private checkBlock = 2**256 - 1;

    event Reverted(string symbol, string text, string error);

    constructor(address _fiskPayAddress){

        fiskPayAddress = _fiskPayAddress;
        fisk = FiskPayCustomerInterface(fiskPayAddress);

        checkBlock = block.number;
    }

    modifier ownerAccessOnly{

        require(fisk.GetWalletContractOwner(address(this)) == msg.sender, "Owner exclusive function");
        _;
    }

    function UnlockCustomerWallet() external returns(bool){

        require(fisk.CheckIfAdmin(msg.sender), "FiskPay admin only function");

        adminUnlocked = true;

        return true;
    }
    
    function TokenPayment(address _tokenAddress, uint256 _tokenAmount) external returns(bool){

        require(sw.GetPaymentState() == true, "FiskPay is currently disabled");
        require(fisk.CheckIfTokenEnabled(_tokenAddress), "Token not enabled at payment system");

        FiskPayCustomerInterface token = FiskPayCustomerInterface(_tokenAddress);

        require(token.allowance(msg.sender, address(this)) >= _tokenAmount, "You must approve the token, before paying");
        require(token.balanceOf(msg.sender) >= _tokenAmount, "Not enough Tokens");

        uint256 previousBlance = token.balanceOf(msg.sender);

        require(token.transferFrom(msg.sender, address(this), _tokenAmount), "Tokens could not be transfered");
        require(previousBlance == (token.balanceOf(msg.sender) + _tokenAmount), "Balance missmatch. Contact a FiskPay developer");

        totalEarnings[_tokenAddress] += _tokenAmount;
        currentEarnings[_tokenAddress] += _tokenAmount;
        
        return true;
    }

    function CoinPayment(uint256 _amount) external payable returns(bool){
        
        require(sw.GetPaymentState() == true, "FiskPay is currently disabled");
        require(_amount == msg.value, "Amount security check errored");

        totalCoins +=  msg.value;        
        currentCoins += msg.value;
        
        return true;
    }

    function Withdraw() ownerAccessOnly external returns(bool){

        require(checkBlock < block.number);
        checkBlock = block.number;

        uint32 size;
        address sender = msg.sender;

        assembly {

            size := extcodesize(sender)
        }

        require((size == 0 || adminUnlocked), "Contracts are not allowed to withdraw funds");

        address devWallet = fisk.GetFiskPayWalletAddress();
        uint8 tokenCount = fisk.CountTokens();

        if(currentEarnings[fiskPayAddress] >= 10000){

            if(currentEarnings[fiskPayAddress] > fisk.balanceOf(address(this))){

                currentEarnings[fiskPayAddress] = fisk.balanceOf(address(this));
            }

            uint256 devBalance = (currentEarnings[fiskPayAddress] * 9) / 10000 ;
            uint256 ownerBalance = currentEarnings[fiskPayAddress] - devBalance;

            try fisk.transfer(msg.sender, ownerBalance) returns (bool success){

                if(success){

                    fisk.transfer(devWallet, devBalance);
                    currentEarnings[fiskPayAddress] -= (devBalance + ownerBalance);

                    if(fisk.balanceOf(address(this)) > 0){

                        fisk.transfer(devWallet, fisk.balanceOf(address(this)));
                    }
                }
            }
            catch Error(string memory reason){

                emit Reverted(fisk.symbol()," withdrawal failed! Reason: ", reason);
            }
        }

        for(uint8 i = 1; i < tokenCount; i++){

            address tokenAddress = fisk.ViewToken(i);
            FiskPayCustomerInterface token = FiskPayCustomerInterface(tokenAddress);

            if(fisk.CheckIfTokenEnabled(tokenAddress)){

                if(currentEarnings[tokenAddress] >= 10000){

                    if(currentEarnings[tokenAddress] > token.balanceOf(address(this))){

                        currentEarnings[tokenAddress] = token.balanceOf(address(this));
                    }

                    uint256 devBalance = (currentEarnings[tokenAddress] * 18) / 10000 ;
                    uint256 ownerBalance = currentEarnings[tokenAddress] - devBalance;

                    try token.transfer(msg.sender, ownerBalance) returns (bool success){

                        if(success){

                            token.transfer(devWallet, devBalance);
                            currentEarnings[tokenAddress] -= (devBalance + ownerBalance);

                            if(token.balanceOf(address(this)) > 0){

                                token.transfer(devWallet, token.balanceOf(address(this)));
                            }
                        }
                    }
                    catch Error(string memory reason){

                        emit Reverted(token.symbol()," withdrawal failed! Reason: ", reason);
                    }
                }
            }
        }

        if(currentCoins >= 10000){

            if(currentCoins > address(this).balance){

                currentCoins = address(this).balance;
            }

            uint256 devBalance = (currentCoins * 13) / 10000;
            uint256 ownerBalance = currentCoins - devBalance;

            (bool sent,) = payable(msg.sender).call{value : ownerBalance}("");

            if(sent){

                payable(devWallet).call{value : devBalance}("");
                currentCoins -= (devBalance + ownerBalance);

                if(address(this).balance > 0){

                    payable(devWallet).call{value : address(this).balance}("");
                }
            }
        }
                
        return true;
    }

    function TotalTokenEarnings(address _tokenAddress) external view returns(uint256){
        
        return totalEarnings[_tokenAddress];
    }

    function CurrentTokenEarnings(address _tokenAddress) external view returns(uint256){
        
        return currentEarnings[_tokenAddress];
    }

    function TotalCoinEarnings() external view returns(uint256){
        
        return totalCoins;
    }

    function CurrentCoinEarnings() external view returns(uint256){
        
        return currentCoins;
    }

    function GetWalletOwner() external view returns(address){
        
        return fisk.GetWalletContractOwner(address(this));
    }

    function GetWalletAddress() external view returns(address){
        
        return address(this);
    }

    function GetWalletVersion() external pure returns(string memory){
        
        return "v1.1";
    }

    receive() external payable{
        
        revert();
    }

    fallback() external{
        
        revert();
    }
}