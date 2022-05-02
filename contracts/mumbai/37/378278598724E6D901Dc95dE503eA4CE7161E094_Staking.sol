pragma solidity 0.8.13;


interface IDepositContract{
    function deposit(
        bytes calldata pubkey,
        bytes calldata withdrawl_credentials,
        bytes calldata signature,
        bytes32 deposit_data_root
    ) external payable;
}


contract Staking{
    mapping(address=>uint) public balances;
    address payable public admin;
    uint public end;
    bool public finalized;
    uint public totalInvested;
    uint public totalChange;
    mapping(address => bool) public changedClaimed;
    mapping(bytes=>bool) public pubKeysUsed;
    IDepositContract public depositContract=IDepositContract(0xa5b344cF49665816D0cD10ca16bae00E8aAAD046);

    event NewInvestor(
        address investor
    );

    constructor(){
        admin=payable(msg.sender);
        end=block.timestamp + 7 days;
    }

    function invest() external payable{
        require(block.timestamp<end, "too late");
        if(balances[msg.sender]==0){
            emit NewInvestor(msg.sender);
        }
        uint fee=msg.value*1/100;
        uint amountInvested=(msg.value)-fee;
        admin.transfer(fee);
        balances[msg.sender]+=amountInvested;
    }

    function finalize() external{
        require(block.timestamp>=end,"too early");
        require(finalized==false,"already finalized");
        finalized=true;
        totalInvested=address(this).balance;
        totalChange=address(this).balance % 32 ether;
        
    }

    function getChange() external{
        require(finalized==true, "not finalized");
        require(balances[msg.sender]>0,"not an investor");
        require(changedClaimed[msg.sender]==false,"change already claimed");
        changedClaimed[msg.sender]=true;
        uint amount=totalChange * balances[msg.sender] / totalInvested;
        address payable senderPayable=payable(msg.sender);
        senderPayable.transfer(amount);
    }

    function deposit(
        bytes calldata pubkey,
        bytes calldata withdrawl_credentials,
        bytes calldata signature,
        bytes32 deposit_data_root
    ) external payable{
        require(finalized==true,"too early");
        require(msg.sender==admin,"only admin");
        require(address(this).balance>=32 ether);
        require(pubKeysUsed[pubkey]==false,"this pubkey was already used");
        depositContract.deposit{value:32 ether}(
            pubkey,
            withdrawl_credentials,
            signature,
            deposit_data_root
        );
    }
}