// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./ERC1155Supply.sol";
import "./Strings.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";

contract Afro is ERC1155, Ownable, ERC1155Supply, ReentrancyGuard {

    event PaymentReceived(address from, uint256 amount);

    string public constant name = "Afro American NFT";
    string private constant symbol = "AAN";
    string public baseURI = "https://ipfs.io/ipfs/QmRXoHYKsbvW1u21NBVyG8LpPcE7feKnEZUbKwE94pWbKB/";
    uint256 public commission = 15;
    uint256 public referralFee = 5;
    uint256[] public mintPrice;
    uint256[] public maxSupply;
    uint256 public ethPrice = 3040;
	bool public status = false;
    bool public onlyAffiliate = true;
	mapping(address => bool) public affiliateList;
	mapping(address => address) public referralList;

    constructor() ERC1155(baseURI) payable {
        addSupply();
    }

    // @dev needed to enable receiving to test withdrawls
    receive() external payable virtual {
        emit PaymentReceived(_msgSender(), msg.value);
    }

    function addSupply() internal {
        for (uint i=0; i<37; i++) {
            mintPrice.push(10);
            mintPrice.push(25);
            mintPrice.push(100);
            mintPrice.push(500);
            mintPrice.push(1000);
            maxSupply.push(100000);
            maxSupply.push(50000);
            maxSupply.push(10000);
            maxSupply.push(10000);
            maxSupply.push(10000);
        }
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

	// @dev admin can mint to a list of addresses with the quantity entered
	function gift(address[] calldata recipients, uint256[] calldata amounts, uint256 id) external onlyOwner {
        uint256 numTokens;
        uint256 i;

        require(id <= maxSupply.length, "Afro: max supply not defined for that id");
        require(recipients.length > 0, "Afro: missing recipients");
        require(recipients.length == amounts.length, 
            "Afro: The number of addresses is not matching the number of amounts");

        //find total to be minted
        for (i = 0; i < recipients.length; i++) {
            numTokens += amounts[i];
            require(recipients[i] != address(0), "Afro: missing address");
            require(Address.isContract(recipients[i]) == false, "Afro: no contracts");
        }

        require(totalSupply(id) + numTokens <= maxSupply[id], "Afro: Can't mint more than the max supply");

        //mint to the list
        for (i = 0; i < recipients.length; i++) {
            _mint(recipients[i], id, amounts[i], "");
        }
	}

    // @dev public minting
    function mint(uint256 _mintAmount, uint256 id, address affiliate) external payable nonReentrant {
        uint256 supply = totalSupply(id);

        require(Address.isContract(msg.sender) == false, "Afro: no contracts");
        require(Address.isContract(affiliate) == false, "Afro: no contracts");
        require(status, "Afro: Minting not started yet");
        require(_mintAmount > 0, "Afro: Cant mint 0");
        require(id <= maxSupply.length, "Afro: max supply not defined for that id");
        require(supply + _mintAmount <= maxSupply[id], "Afro: Cant mint more than max supply");
        require(msg.value >= mintPrice[id] * 1e18 / ethPrice * _mintAmount, "Afro: Must send eth of cost per nft");

        _mint(msg.sender, id, _mintAmount, "");

        //if address is owner then no payout
        if (affiliate != address(0) && affiliate != owner() && commission > 0) {
            //if only recorded affiliates can receive payout
            if (onlyAffiliate == false || (onlyAffiliate && affiliateList[affiliate])) {
                if (referralList[affiliate] == address(0) || referralList[affiliate] == owner()) {
                    Address.sendValue(payable(affiliate), mintPrice[id] * _mintAmount * commission / 100);
                } else {
                    //pay the referrer of the affiliate some of the commission
                    Address.sendValue(payable(referralList[affiliate]), mintPrice[id] * _mintAmount * referralFee / 100);
                    Address.sendValue(payable(affiliate), mintPrice[id] * _mintAmount * (commission - referralFee) / 100);
                }
            }
        }
    }

    // @dev record affiliate address   
	function allowAffiliate(address newAffiliate, bool allow, address referral) external onlyOwner {
        require(newAffiliate != address(0), "Afro: not valid address");
        require(Address.isContract(newAffiliate) == false, "Afro: no contracts");
        require(Address.isContract(referral) == false, "Afro: no contracts");
        affiliateList[newAffiliate] = allow;
        referralList[newAffiliate] = referral;
	}

    // @dev set cost of minting in dollars
	function setMintPrice(uint256 _newmintPrice, uint256 id) external onlyOwner {
        require(id <= maxSupply.length, "Afro: max supply not defined for that id");
    	mintPrice[id] = _newmintPrice;
	}
		
    // @dev set commission amount in percentage
 	function setCommission(uint256 _newCommission) external onlyOwner {
        require(_newCommission > referralFee, "Afro: commission must be greater than referral fee");
        commission = _newCommission;
	}

    // @dev set commission amount in percentage
 	function setReferral(uint256 _newFee) external onlyOwner {
        require(commission > _newFee, "Afro: commission must be greater than referral fee");
        referralFee = _newFee;
	}

   // @dev if only recorded affiliate can receive payout 
	function setOnlyAffiliate(bool _affiliate) external onlyOwner {
    	onlyAffiliate = _affiliate;
	}

   // @dev unpause main minting stage
	function setStatus(bool _status) external onlyOwner {
    	status = _status;
	}
	
    // @dev Set the base url path to the metadata used by opensea
    function setBaseURI(string memory _baseTokenURI) external onlyOwner {
        baseURI = _baseTokenURI;
    }

    // @dev Set the price of ethereum
    function setEth(uint256 price) external onlyOwner {
        require(price > 0, "Afro: price is invalid");
        ethPrice = price;
    }

    function cost(uint256 id) public view returns (uint256) {
        return mintPrice[id] * 1e18 / ethPrice;
    }

    function maxID() public view returns (uint256) {
        return maxSupply.length;
    }

    // @dev used to reduce the max supply instead of a burn
    function reduceMaxSupply(uint256 newMax, uint256 id) external onlyOwner {
        require(id <= maxSupply.length, "Afro: max supply not defined for that id");
        require(newMax < maxSupply[id], "Afro: New maximum must be less than existing maximum");
        require(newMax >= totalSupply(id), "Afro: New maximum can't be less than minted count");
        maxSupply[id] = newMax;
    }

    function addID(uint256[] calldata _supply, uint256[] calldata _cost) external onlyOwner {
        uint256 i;

        require(_supply.length == _cost.length, "Afro: The number of supply is not matching the number of cost");

        for (i = 0; i < _supply.length; i++) {
            require(_supply[i] > 0, "Afro: max supply missing");
            require(_cost[i] > 0, "Afro: max supply missing");
        }

        for (i = 0; i < _supply.length; i++) {
            mintPrice.push(_cost[i]);
            maxSupply.push(_supply[i]);
        }
    }

    // @dev used to withdraw erc20 tokens like DAI
    function withdrawERC20(IERC20 token, address to) external onlyOwner {
        require(Address.isContract(to) == false, "Afro: no contracts");
        token.transfer(to, token.balanceOf(address(this)));
    }

    // @dev used to withdraw eth
    function withdraw(address payable to) external onlyOwner {
        require(Address.isContract(to) == false, "Afro: no contracts");
        Address.sendValue(to,address(this).balance);
    }

    function uri(uint256 _tokenId) override public view returns (string memory) {
        return string(abi.encodePacked(baseURI,Strings.toString(_tokenId),".json"));
    }
    
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override (ERC1155, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}