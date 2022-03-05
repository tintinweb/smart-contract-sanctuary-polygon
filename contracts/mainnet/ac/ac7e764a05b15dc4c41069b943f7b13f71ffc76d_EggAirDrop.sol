// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;
import "./Ownable.sol";

contract FountainTokenInterface is Ownable {
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual {}

    function ownerOf(uint256 tokenId) public view virtual returns (address) {}

    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        returns (bool)
    {}
}

contract EggAirDrop is Ownable {
    string public name = "EGGAirDrop";
    address private contractAddr;
    FountainTokenInterface fountain = FountainTokenInterface(contractAddr);
    
    function airDrop(
        address _owner,
        address[] memory addrs,
        uint256[] memory tokens
    ) public onlyOwner {
        require(addrs.length == tokens.length, "error");
        require(
            fountain.isApprovedForAll(_owner, address(this)),
            "Not authorized"
        );
        require(checkAllTokenOwner(_owner, tokens), "Token Error");
        for (uint256 i = 0; i < addrs.length; i++) {
            fountain.safeTransferFrom(_owner, addrs[i], tokens[i]);
        }
    }

    function checkAllTokenOwner(address _owner, uint256[] memory tokens)
        internal
        view
        virtual
        returns (bool)
    {
        for (uint256 i = 0; i < tokens.length; i++) {
            if (fountain.ownerOf(tokens[i]) != _owner) {
                return false;
            }
        }
        return true;
    }

    function setContractAddr(address addr) public onlyOwner {
        contractAddr = addr;
    }
}