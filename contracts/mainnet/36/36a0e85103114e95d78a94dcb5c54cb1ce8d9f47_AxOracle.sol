/**
 *Submitted for verification at polygonscan.com on 2022-07-26
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.2;

 interface IERC20 {
    function decimals() external view returns (uint8);
}
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

 
    function owner() public view virtual returns (address) {
        return _owner;
    }


    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }


    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

  
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract AxOracle is Ownable {
    address[] private _calculations;
    address public usdcAddress;
    mapping(address => address) public tokenAliases;

    event TokenAliasAdded(address tokenAddress, address tokenAliasAddress);
    event TokenAliasRemoved(address tokenAddress);

    struct TokenAlias {
        address tokenAddress;
        address tokenAliasAddress;
    }

    constructor( address _usdcAddress)
    {
        usdcAddress = _usdcAddress;
    }

   
    function setCalculations(address[] memory calculationAddresses)
        public
        onlyOwner()
    {
        _calculations = calculationAddresses;
    }

    function calculations() external view returns (address[] memory) {
        return (_calculations);
    }

    function addTokenAlias(address tokenAddress, address tokenAliasAddress)
        public
        onlyOwner
    {
        tokenAliases[tokenAddress] = tokenAliasAddress;
        emit TokenAliasAdded(tokenAddress, tokenAliasAddress);
    }

    function addTokenAliases(TokenAlias[] memory _tokenAliases)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < _tokenAliases.length; i++) {
            addTokenAlias(
                _tokenAliases[i].tokenAddress,
                _tokenAliases[i].tokenAliasAddress
            );
        }
    }

    function removeTokenAlias(address tokenAddress) public onlyOwner {
        delete tokenAliases[tokenAddress];
        emit TokenAliasRemoved(tokenAddress);
    }

    function getNormalizedValueUsdc(
        address tokenAddress,
        uint256 amount,
        uint256 priceUsdc
    ) public view returns (uint256) {
        IERC20 token = IERC20(tokenAddress);
        uint256 tokenDecimals = token.decimals();

        uint256 usdcDecimals = 6;
        uint256 decimalsAdjustment;
        if (tokenDecimals >= usdcDecimals) {
            decimalsAdjustment = tokenDecimals - usdcDecimals;
        } else {
            decimalsAdjustment = usdcDecimals - tokenDecimals;
        }
        uint256 value;
        if (decimalsAdjustment > 0) {
            value =
                (amount * priceUsdc * (10**decimalsAdjustment)) /
                10**(decimalsAdjustment + tokenDecimals);
        } else {
            value = (amount * priceUsdc) / 10**usdcDecimals;
        }
        return value;
    }

    function getNormalizedValueUsdc(address tokenAddress, uint256 amount)
        external
        view
        returns (uint256)
    {
        uint256 priceUsdc = getPriceUsdcRecommended(tokenAddress);
        return getNormalizedValueUsdc(tokenAddress, amount, priceUsdc);
    }

    function getPriceUsdcRecommended(address tokenAddress)
        public
        view
        returns (uint256)
    {
        address tokenAddressAlias = tokenAliases[tokenAddress];
        address tokenToQuery = tokenAddress;
        if (tokenAddressAlias != address(0)) {
            tokenToQuery = tokenAddressAlias;
        }
        (bool success, bytes memory data) =
            address(this).staticcall(
                abi.encodeWithSignature("getPriceUsdc(address)", tokenToQuery)
            );
        if (success) {
            return abi.decode(data, (uint256));
        }
        return 0;
    }

   
    fallback() external {
        for (uint256 i = 0; i < _calculations.length; i++) {
            address calculation = _calculations[i];
            assembly {
                let _target := calculation
                calldatacopy(0, 0, calldatasize())
                let success := staticcall(
                    gas(),
                    _target,
                    0,
                    calldatasize(),
                    0,
                    0
                )
                returndatacopy(0, 0, returndatasize())
                if success {
                    return(0, returndatasize())
                }
            }
        }
        revert("Oracle: Fallback proxy failed to return data");
    }
}