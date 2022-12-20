// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.19;

//import openzepplin
import "./ERC20Upgradable.sol";

//begining of token contract
contract SPQ is ERC20Upgradeable{
    address public owner;
    mapping(bytes4 => bool) private isRun;
    mapping(bytes4 => bool) private isColdWalletAddressSet;
    address public SEED_WALLET;
    address public ANGEL_WALLET;
    address public FOUNDERS_WALLET;
    address public AIR_DROP_WALLET;
    address public MARKET_WALLET;
    address public LIQUIDITY_WALLET;
    address public TREASURY_WALLET;
    address public OPERATIONAL_WALLET;
    address public DUMMY_WALLET;


    address public timeLock;

    uint256 private  _wei;





    function initialize(address _owner) external initializer {
        __ERC20_init("Prakash", "PKC");
        owner = _owner; // set initial value in initialiowner = msg.sender;
        _wei= 1000000000000000000;


    }
    function start() external returns(bool){
        isOwner();once();
        //ensure all the wallets has beens set
        require(SEED_WALLET != address(0), "Seed wallet not set");
        require(ANGEL_WALLET != address(0), "Angel wallet not set");
        require(FOUNDERS_WALLET != address(0), "Founders wallet not set");
        require(AIR_DROP_WALLET != address(0), "Airdrop wallet not set");
        require(MARKET_WALLET != address(0), "Market wallet not set");
        require(LIQUIDITY_WALLET != address(0), "Liquidity wallet not set");
        require(TREASURY_WALLET != address(0), "Treasury wallet not set");
        require(OPERATIONAL_WALLET != address(0), "Operational wallet not set");
        require(DUMMY_WALLET != address(0), "Dummy wallet not set");
        //mint 1B, the NPTR should have trannsfer ownership before this function call
        require(mint(1000000000)==true,"Minting is not done");
        //transfer 4% to SEED_WALLET
        sendTo(owner,SEED_WALLET, ((4 *1000000000) / 100) * _wei);
        // transfer 10% to ANGEL_WALLET
        sendTo(owner,ANGEL_WALLET, ((10 *1000000000) / 100) * _wei);
        //transfer 15 % to founderWallet
        sendTo(owner,FOUNDERS_WALLET, ((15 * 1000000000) / 100 ) * _wei) ;
        //transfer 2.997 % to AIR_DROP_WALLET
        sendTo(owner,AIR_DROP_WALLET, ((2.997 * 1000000000) / 100) * _wei);
        //transfer 6 % to MARKET_WALLET
        sendTo(owner,MARKET_WALLET, ((6 * 1000000000) / 100)* _wei);
        //transfer 12 % to LIQUIDITY_WALLET
        sendTo(owner,LIQUIDITY_WALLET, ((12 *1000000000) / 100)* _wei);
        //transfer 30 % to TREASURY_WALLET
        sendTo(owner,TREASURY_WALLET, ((30 *1000000000) / 100)* _wei);
        //transfer 20 % to OPERATIONAL_WALLET
        sendTo(owner,OPERATIONAL_WALLET, ((20 *1000000000) / 100)* _wei);
        //transfer 0.003% to dummy wallet
        sendTo(owner, DUMMY_WALLET, ((0.003 * 1000000000)/100)* _wei);

        return true;
    }
    //to start minting
    function mint(uint256 amount) public  returns (bool){
        //to mint, only done by owner
        isOwner();isEnable();
        _mint(owner, amount * _wei);
        return true;
    }
    //to send tokens to
    function sendTo(address from, address to, uint256 amount) public returns(bool){
        //to transfer minted tokens to
        isOwner();isEnable();
        require(balanceOf(from) >= amount, "Insufficient amount");

        // Owner cannot send funds from cold wallets
        require(from != SEED_WALLET, "Cannot send funds from cold wallet");
        require(from != AIR_DROP_WALLET, "Cannot send funds from cold wallet");
        require(from != MARKET_WALLET, "Cannot send funds from cold wallet");
        require(from != FOUNDERS_WALLET, "Cannot send funds from cold wallet");
        require(from != TREASURY_WALLET, "Cannot send funds from cold wallet");
        require(from != LIQUIDITY_WALLET, "Cannot send funds from cold wallet");
        require(from != DUMMY_WALLET, "Cannot send funds from cold wallet");
        require(from != ANGEL_WALLET, "Cannot send funds from cold wallet");
        require(from != OPERATIONAL_WALLET, "Cannot send funds from cold wallet");


        _transfer(from, to, amount);
        return true;
    }
    //to burn tokens only by  ADMIN
    function burn(uint256 amount, address from) external  returns (bool){
        isOwner();isEnable();
        require(_balances[from] >= amount, "Insufficient amount");
        _burn(from, amount);
        return true;
    }

    //to disable and enable token
    function enableToken(bool _value) external returns (bool){
        isOwner();
        _enable(_value);
        return true;
    }
    //to transfer ownership
    function makeAdmin(address _address) external returns (bool){
        //transfer ownership status
        isOwner();
        owner = _address;
        return true;
    }

    //get available minted tokens
    function mintedTokens() external view returns (uint256 bal){
        //transfer ownership status
        bal = balanceOf(address(this));
        return bal;
    }
    //to change the tradding wallet or reward wallet
    function setAddress(address _seedWallet, address _angelWallet, address _foundersWallet, address _airdropWallet, address _marketWallet, address _liquidityWallet, address _treasuryWallet, address _operationalWallet, address _dummyWallet) external returns(bool){
        isOwner();coldWalletAddress();
            SEED_WALLET = _seedWallet;
            ANGEL_WALLET = _angelWallet;
            FOUNDERS_WALLET = _foundersWallet;
            AIR_DROP_WALLET = _airdropWallet;
            MARKET_WALLET = _marketWallet;
            LIQUIDITY_WALLET = _liquidityWallet;
            TREASURY_WALLET = _treasuryWallet;
            OPERATIONAL_WALLET = _operationalWallet;
            DUMMY_WALLET = _dummyWallet;

        return true;
    }


    //check ownership
    function isOwner() internal view{
        require(owner == msg.sender, "Can only be done by Owner");

    }
    //this modifier allows this function to be done once
    function once() private returns (bool){
        require(isRun[msg.sig] == false, "This method has already being called");
        //set it to as being called
        isRun[msg.sig] = true;
        return true;
    }
    function coldWalletAddress() private returns (bool){
        require(isColdWalletAddressSet[msg.sig] == false, "Cold Wallet Address already set");
        //set it to as being called
        isColdWalletAddressSet[msg.sig] = true;

        return true;
    }
}