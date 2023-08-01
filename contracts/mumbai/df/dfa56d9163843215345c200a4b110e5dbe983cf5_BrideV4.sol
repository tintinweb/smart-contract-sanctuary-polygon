/**
 *Submitted for verification at polygonscan.com on 2023-07-31
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;


contract Ownable {
    address public owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

interface IERC677Receiver {
    function onTokenTransfer(
        address from,
        uint256 amount,
        bytes calldata data
    ) external;
}

contract TestToken is Ownable {
    string public name;
    string public symbol;
    uint8 public decimals;
    bool mintAllowed = true;
    uint256 public currentCirculation;
    uint256 decimalfactor;
    uint256 public Max_Token;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event TokenTransfer(
        address indexed from,
        address indexed to,
        uint256 value,
        bytes data
    );
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);

    constructor() {
        symbol = "BT";
        name = "BridgeToken";
        decimals = 18;
        decimalfactor = 10**uint256(decimals);
        Max_Token = 500_000_000 * decimalfactor;

        mint(msg.sender, 50_000_000 * decimalfactor);
    }

    function approve(address _spender, uint256 _value)
        public
        returns (bool success)
    {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    function increaseAllowance(address _spender, uint256 _value)
        public
        returns (bool sucess)
    {
        allowance[msg.sender][_spender] += _value;
        return true;
    }

    function decreseAllowance(address _spender, uint256 _value)
        public
        returns (bool sucess)
    {
        allowance[msg.sender][_spender] -= _value;
        return true;
    }

    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        currentCirculation -= _value;
        emit Burn(msg.sender, _value);
        return true;
    }

    function mint(address _to, uint256 _value) public returns (bool success) {
        require(Max_Token >= (currentCirculation + _value));
        require(mintAllowed, "Max supply reached");
        if (Max_Token == (currentCirculation + _value)) {
            mintAllowed = false;
        }
        require(msg.sender == owner, "Only Owner Can Mint");
        balanceOf[_to] += _value;
        currentCirculation += _value;
        require(balanceOf[_to] >= _value);
        emit Transfer(address(0), _to, _value);
        return true;
    }

    function _transfer(address _from,address _to,uint256 _value) internal {
        require(_to != address(0));
        require(balanceOf[_from] >= _value);

        require(balanceOf[_to] + _value >= balanceOf[_to]);
        uint256 previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;

        emit Transfer(_from, _to, _value);
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender], "Allowance error");
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    function transferAndCall(address _to,uint256 _value,bytes calldata _data) external returns (bool) {
        require(_to != address(0), "ERC677: Invalid recipient address");
        require(balanceOf[msg.sender] >= _value, "ERC677: Insufficient balance");
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        uint256 previousBalances = balanceOf[msg.sender] + balanceOf[_to];
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
      
        emit TokenTransfer(msg.sender, _to, _value, _data);

        assert(balanceOf[msg.sender] + balanceOf[_to] == previousBalances);
        return true;
    }

}

contract BrideV4{
    uint256 private TotalTokenBalance;
    uint256 private LockedTokens;
    uint256 public UnlockedTokens;
    uint256 public Nonce;
    TestToken public ContractInstance;
    address public Owner;
    uint256 public nonce;


    enum Step{Mint,Burn}              //Mint = 0,Burn = 1
    event Transfer(
        address from,
        address to,
        uint256 value,
        uint256 date,
        uint256 nonce,
        Step indexed step
    );

     modifier onlyOwner() {
        require(msg.sender == Owner);
        _;
    }

     constructor(address _contractInstance) {
        ContractInstance = TestToken(_contractInstance);
        Owner = msg.sender;
    }

   
    function deposite() external payable {}

    function getBridgebalance() public view returns(uint256){
        return address(this).balance;
    }

    function UserTokenBalance(address user)public view returns(uint256){
       return  ContractInstance.balanceOf(user);
    }


    function burnToken(uint256 value)external onlyOwner returns(bool){
        ContractInstance.burn(value);
        emit Transfer(msg.sender, address(this), value, block.timestamp, nonce, Step.Burn);
        return true;
    }

    function mintToken(address to,uint256 value)external  onlyOwner returns(bool){
        ContractInstance.mint(to,value);
        emit Transfer(msg.sender, to, value, block.timestamp, nonce, Step.Mint);
        return true;
    }


}