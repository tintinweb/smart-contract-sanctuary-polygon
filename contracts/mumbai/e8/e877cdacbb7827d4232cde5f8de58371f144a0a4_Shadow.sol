pragma solidity ^0.5.0;
import "./Folia.sol";
import "./IShadowController.sol";

/*        
By David Rudnick
Produced by Folia.app
*/

contract Shadow is Folia {
    constructor(address recipient, address _metadata) public Folia("House SHADOW", "SHD", _metadata){
        for (uint256 i = 1; i <= 36; i++) {
            _mint(recipient, i); // tombcouncil.eth
        }
    }
    function transferFrom(address from, address to, uint256 tokenId) public {
        require(_isApprovedOrOwner(msg.sender, tokenId));
        require(!IShadowController(controller).isLocked(from, to, tokenId), "SHADOW is locked");
        _transferFrom(from, to, tokenId);
    }

}