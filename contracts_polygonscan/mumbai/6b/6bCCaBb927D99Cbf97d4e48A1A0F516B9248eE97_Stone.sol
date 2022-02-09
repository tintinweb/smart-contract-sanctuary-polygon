// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

contract Stone {
/*======================== Events =================================*/
    event Transfer(address from, address to, uint256 amount);
    event BlacklistAdded(address user);
    event BlacklistRemoved(address user);
    event WhitelistContractAdded(address conAdd);


/*========================== Modifiers ============================*/
modifier onlyAdmin(){
    require(msg.sender == admin,"Stone: Only admin");
    _;
}
/*========================== State Variables ======================*/
    uint256 private tokenTotalSupply;

    string private tokenName;
    string private tokenSymbol;

    address public admin;
    mapping(address => uint256) private balances;
    mapping(address => bool) private blacklist;
    mapping(address => bool) private whitelistedContracts;

/*=========================== Constructor ==========================*/
    constructor(string memory _tokenName, string memory _tokenSymbol, address _admin, address[] memory _conAdd) {
        tokenName = _tokenName;
        tokenSymbol = _tokenSymbol;
        admin = _admin;
        for(uint8 i = 0; i < _conAdd.length; i++){
            setWhitelistedContract(_conAdd[i]);
        }
    }
/*=========================== Read Functions =======================*/
    function name() public view returns (string memory) {
        return tokenName;
    }
    function symbol() public view returns (string memory) {
        return tokenSymbol;
    }
    function decimals() public pure  returns (uint8) {
        return 18;
    }
    function totalSupply() public view  returns (uint256) {
        return tokenTotalSupply;
    }
    function balanceOf(address _account) public view  returns (uint256) {
        return balances[_account];
    }
    function isBlacklisted(address _user) public view returns(bool){
        return blacklist[_user];
    }
    function isWhitelistedContract(address _contract) public view returns(bool){
        return whitelistedContracts[_contract];
    }
/*========================== Public Functions =================================*/
    function giveAway(address _to, uint256 _amount) public onlyAdmin{
        require(_to != address(0) && _amount >0,"Stone: Missing argument");
        require(blacklist[_to] == false,"Stone: User blacklisted");
        _mint(_to, _amount);

    }
    function createReward(uint256 _amount) external {
        require(isWhitelistedContract(msg.sender) == true,"Stone: not whitelisted contract");
        _mint(msg.sender, _amount);
    }
    function addBlacklist(address _user) public onlyAdmin{
        require(!isBlacklisted(_user),"Stone: Already Blacklisted");
        blacklist[_user] = true;
        
        emit BlacklistAdded(_user);
    }
    function removeBlacklist(address _user) public onlyAdmin{
        require(isBlacklisted(_user),"Stone: Not Blacklisted");
        delete blacklist[_user];

        emit BlacklistRemoved(_user);

    } 
    function setWhitelistedContract(address _conAdd) public onlyAdmin{
        whitelistedContracts[_conAdd] = true;
        emit WhitelistContractAdded(_conAdd);
    }
    function spendStone(address _user,uint256 _amount) external {
        require(msg.sender == _user,"Stone: only own wallet");
        _burn(_user, _amount);
    }
/*========================== Internal Functions ===============================*/
    function _mint(address _account, uint256 _amount) internal virtual {
        require(_account != address(0), "Stone: mint to the zero address");

        tokenTotalSupply += _amount;
        balances[_account] += _amount;

        emit Transfer(address(0), _account, _amount);

    }
    function _burn(address _account, uint256 _amount) internal virtual {
        require(_account != address(0), "Stone: zero address");

        uint256 _accountBalance = balances[_account];
        require(_accountBalance >= _amount, "Stone: exceeds balance");
        unchecked {
            balances[_account] = _accountBalance - _amount;
        }
        tokenTotalSupply -= _amount;

        emit Transfer(_account, address(0), _amount);

    }

}