/**
 *Submitted for verification at polygonscan.com on 2023-06-07
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19 <0.9.0;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function mint(uint amount, address recipient) external;
    function burn(uint amount) external;
}

interface IDDT {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address recipient, uint amount) external returns (bool);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);
    function mint(uint amount, address recipient) external;
    function burn(uint amount) external;
}

interface IDERC20 {
    function name() external  view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);

    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);

}



// This contract is not Upgradable
contract PoLottoExchange {

    //deployed on Polygon Mumbai testnet for development
    address private DDT = 0x69bd7Dd66897AcBd2EaECc9669e9890Cd5b6Bb9E;
    // polygon erc20 faucet. a substitution for USDC
    address private DERC = 0xfe4F5145f6e09952a5ba9e956ED0C25e3Fa4c7F1;

    mapping(address => uint) public balances;

    event Transfer (address origin, address destination, uint256 amount, address token);

    function balanceofDERC (address a) public view returns (uint256) {
        return IDERC20(DERC).balanceOf(a);
    }

    function balanceofDDT (address a) public view returns (uint256) {
        return IDDT(DDT).balanceOf(a);
    }

    function deposite (uint256 amount_wei, address token) external payable {
        require(token == DERC, "Only allow USDC to be deposite");

        //bool approveb = IDERC20(DERC).approve(address(this), amount_wei);
        //require(approveb == false, "Approval unsuccessful");
        //require(IDERC20(DERC).allowance(msg.sender, address(this)) >= amount_wei, "Not approved to send balance requested");
        // user have to call approve from frontend interaction.
        bool b = _deposite(amount_wei);
        require(b == true, "USDC transfer unsuccessful");
        balances[msg.sender] += amount_wei;
        emit Transfer (msg.sender, address(this), amount_wei, token);
        _receipt(amount_wei,msg.sender);
        emit Transfer (DDT, msg.sender, amount_wei, DDT);
    }

    function _deposite (uint256 amount_wei) internal returns (bool) {
        bool b = IDERC20(DERC).transferFrom(msg.sender, address(this), amount_wei);
        return b;
    }

    function _receipt (uint256 amount_wei, address user) internal {
        IDDT(DDT).mint(amount_wei,user);
    }

    function withdraw (uint256 amount) external {
        // Approve DDT to be sent to contract
        require(balances[msg.sender] >= amount, "Insufficient Funds");
        IDERC20(DERC).transfer(msg.sender,amount);
        emit Transfer(address(this), msg.sender, amount, DERC);
        IDDT(DDT).transferFrom(msg.sender, address(this), amount);
        emit Transfer(msg.sender, address(this), amount, DERC);
        IDDT(DDT).burn(amount);
        balances[msg.sender] -= amount;
    }
    
}


//1000000000000000000
//3000000000000000000