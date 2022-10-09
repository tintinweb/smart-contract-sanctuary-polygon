/**
 *Submitted for verification at polygonscan.com on 2022-10-08
*/

/**
 *Submitted for verification at Etherscan.io on 2022-03-03
*/

pragma solidity 0.8.7;

interface PnsAddressesInterface {
    function owner() external view returns (address);
    function getPnsAddress(string memory _label) external view returns(address);
}

pragma solidity 0.8.7;

interface PnsRegistryInterface {
    function owner() external view returns (address);
    function getPnsAddress(string memory _label) external view returns (address);
    function setRecord(bytes32 _hash, uint256 _tokenId, string memory _name, uint256 _expiration) external;
    function getTokenID(bytes32 _hash) external view returns (uint256);
    function getOwnerOf(uint256 _tokenId) external view returns (address);
    function getName(uint256 _tokenId) external view returns (string memory);
    function setNewOwner(uint256 _tokenId, address _owner, uint256 _expiration) external;
    function setRenewal(uint256 _tokenId, address _owner, uint256 _expiration) external;
}

pragma solidity 0.8.7;

interface PnsErc721Interface {
    function mintErc721(address to) external;
    function getNextTokenId() external view returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address);
    function emitTransferEvent(address _from, address _to, uint256 _tokenID) external;
}

pragma solidity 0.8.7;

interface PnsPricesOracleInterface {
    function getMaticCost(string memory _name, uint256 expiration) external view returns (uint256);
    function getEthCost(string memory _name, uint256 expiration) external view returns (uint256);
}

pragma solidity 0.8.7;

interface IERC20 {
    
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

pragma solidity 0.8.7;

abstract contract PnsAddressesImplementation is PnsAddressesInterface {
    address private PnsAddresses;
    PnsAddressesInterface pnsAddresses;

    constructor(address addresses_) {
        PnsAddresses = addresses_;
        pnsAddresses = PnsAddressesInterface(PnsAddresses);
    }

    function setAddresses(address addresses_) public {
        require(msg.sender == owner(), "Not authorized.");
        PnsAddresses = addresses_;
        pnsAddresses = PnsAddressesInterface(PnsAddresses);
    }

    function getPnsAddress(string memory _label) public override view returns (address) {
        return pnsAddresses.getPnsAddress(_label);
    }

    function owner() public override view returns (address) {
        return pnsAddresses.owner();
    }
}


pragma solidity 0.8.7;

contract Computation {
    function computeNamehash(string memory _name) public pure returns (bytes32 namehash) {
        namehash = 0x0000000000000000000000000000000000000000000000000000000000000000;
        namehash = keccak256(
        abi.encodePacked(namehash, keccak256(abi.encodePacked('eth')))
        );
        namehash = keccak256(
        abi.encodePacked(namehash, keccak256(abi.encodePacked(_name)))
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

contract PnsRegistrar is Computation, PnsAddressesImplementation {

    IERC20 ethToken;

    constructor(address addresses_, address tokenAddress) PnsAddressesImplementation(addresses_) {
        ethToken = IERC20(tokenAddress);
    }

    function setErc20Eth(address tokenAddress) public {
        require(msg.sender == owner(), "Not authorized.");
        ethToken = IERC20(tokenAddress);
    }

    bool public isActive = true;

    struct Register {
        string name;
        address registrant;
        uint256 expiration;
    }

    struct Renew {
        uint256 tokenId;
        uint256 expiration;
    }

    function pnsRegister(Register[] memory register) public payable {
        require(isActive, "Registration must be active.");
        require(totalCostMatic(register) <= msg.value, "Ether value is not correct.");
        for(uint256 i=0; i<register.length; i++) {
            _register(register[i]);
        }
    }

    function pnsRegisterWithErc20(Register[] memory register) public {
        require(isActive, "Registration must be active.");
        require(totalCostEth(register) <= ethToken.allowance(msg.sender, address(this)), "Ether value not authorized.");
        for(uint256 i=0; i<register.length; i++) {
            _register(register[i]);
        }
        ethToken.transferFrom(msg.sender, address(this), totalCostEth(register));
    }

    function pnsRegisterMinter(Register[] memory register) public {
        require(isActive, "Registration must be active.");
        require(msg.sender == getPnsAddress("_pnsMinter"), "Not authorized.");
        for(uint256 i=0; i<register.length; i++) {
            _register(register[i]);
        }
    }

    function _register(Register memory register) internal {
        PnsErc721Interface pnsErc721 = PnsErc721Interface(getPnsAddress("_pnsErc721"));
        PnsRegistryInterface pnsRegistry = PnsRegistryInterface(getPnsAddress("_pnsRegistry"));
        require(register.expiration != 0, "Invalid duration.");
        require(checkString(register.name) == true, "Invalid string.");
        bytes32 _hash = computeNamehash(register.name);
        
        uint256 currentTokenID = pnsRegistry.getTokenID(_hash);
        if (currentTokenID == 0) {
            uint256 _tokenId = pnsErc721.getNextTokenId();
            pnsErc721.mintErc721(register.registrant);
            pnsRegistry.setRecord(_hash, _tokenId, register.name, register.expiration);
        } else {
            address previousOwner = pnsRegistry.getOwnerOf(currentTokenID);
            require(previousOwner == address(0), "Name already exists.");
            pnsRegistry.setNewOwner(currentTokenID, register.registrant, register.expiration);
            pnsErc721.emitTransferEvent(previousOwner, register.registrant, currentTokenID);
        }
    }

    function pnsRenewNames(Renew[] memory renew) public payable {
        require(isActive, "Registration must be active.");
        require(totalRenewalCostMatic(renew) <= msg.value, "Ether value is not correct.");
        for(uint256 i=0; i<renew.length; i++) {
            _renew(renew[i]);
        }
    }

    function _renew(Renew memory renew) internal {
        PnsRegistryInterface pnsRegistry = PnsRegistryInterface(getPnsAddress("_pnsRegistry"));
        require(renew.expiration != 0, "Invalid duration.");
        address currentOwner = pnsRegistry.getOwnerOf(renew.tokenId);
        require(currentOwner == msg.sender, "Not owned.");
        pnsRegistry.setRenewal(renew.tokenId, currentOwner, renew.expiration);        
    }

    function totalRenewalCostMatic(Renew[] memory renew) internal view returns (uint256) {
        PnsRegistryInterface pnsRegistry = PnsRegistryInterface(getPnsAddress("_pnsRegistry"));
        PnsPricesOracleInterface pnsPricesOracle = PnsPricesOracleInterface(getPnsAddress("_pnsPricesOracle"));
        uint256 totalCost;
        for(uint256 i=0; i<renew.length; i++) {
            totalCost = totalCost + pnsPricesOracle.getMaticCost(pnsRegistry.getName(renew[i].tokenId), renew[i].expiration);
        }
        return totalCost;
    }

    function totalCostMatic(Register[] memory register) internal view returns (uint256) {
        PnsPricesOracleInterface pnsPricesOracle = PnsPricesOracleInterface(getPnsAddress("_pnsPricesOracle"));
        uint256 totalCost;
        for(uint256 i=0; i<register.length; i++) {
            totalCost = totalCost + pnsPricesOracle.getMaticCost(register[i].name, register[i].expiration);
        }
        return totalCost;
    }

    function totalCostEth(Register[] memory register) internal view returns (uint256) {
        PnsPricesOracleInterface pnsPricesOracle = PnsPricesOracleInterface(getPnsAddress("_pnsPricesOracle"));
        uint256 totalCost;
        for(uint256 i=0; i<register.length; i++) {
            totalCost = totalCost + pnsPricesOracle.getEthCost(register[i].name, register[i].expiration);
        }
        return totalCost;
    }

    function checkString(string memory str) public pure returns (bool){
        bytes memory b = bytes(str);
        if(b.length > 15) return false;
        if(b.length < 3) return false;

        for(uint i; i<b.length; i++){
            bytes1 char = b[i];
            if(
                (char == 0x2e)
            )
                return false;
        }
        return true;
    }

    function withdraw(address to, uint256 amount) public {
        require(msg.sender == owner());
        require(amount <= address(this).balance);
        payable(to).transfer(amount);
    }

    function withdrawEth(address to, uint256 amount) public {
        require(msg.sender == owner());
        require(ethToken.balanceOf(address(this)) >= amount, "Value greater than balance.");
        ethToken.transferFrom(address(this), to, amount);
    }
    
    function flipActiveState() public {
        require(msg.sender == owner());
        isActive = !isActive;
    }

}