// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.7.6;
pragma experimental ABIEncoderV2;

import "../core/walletData.sol";
import "../ens/ensResolver.sol";
import "../ens/registrarInterface.sol";

library NameService {
	// event NameRegistered(string subdomain, string domain, uint cost);

	// namehash('one')
	bytes32 public constant TLD_NODE =
		0x30f9ae3b1c4766476d11e2bacd21f9dff2c59670d8b8a74a88ebc22aec7020b9;

	function registerENS(
		address resolver,
		string calldata subdomain,
		string calldata domain,
		uint256 duration
	) public {
		bytes32 label = keccak256(bytes(domain));
		address resolved = Resolver(resolver).addr(
			keccak256(abi.encodePacked(TLD_NODE, label))
		);

		// uint256 rentPriceSub = RegistrarInterface(resolved).rentPrice(subdomain, duration);
		// require(address(this).balance >= rentPriceSub, "NOT ENOUGH TO REGISTER NAME");

		RegistrarInterface(resolved).register(
			label,
			subdomain,
			address(this),
			duration,
			"",
			resolver
		);
	}
}

// SPDX-License-Identifier:GPL-3.0-only

pragma solidity >=0.7.6;
pragma experimental ABIEncoderV2;

library Core {
	enum OwnerSignature {
		// TODO: remove Anyone? It is not used
		Anyone, // Anyone
		Owner, // Owner required
		OwnerOrGuardian, // Owner and/or guardians
		Guardian, // Guardians only
		// TODO: remove Session? It is not used
		Session // Session only
	}

	struct SignatureRequirement {
		uint8 requiredSignatures;
		OwnerSignature ownerSignatureRequirement;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6;

/**
 * @title EnsResolver
 * @dev Extract of the interface for ENS Resolver
 */
interface Resolver {
	function supportsInterface(bytes4 interfaceID) external pure returns (bool);

	function addr(bytes32 node) external view returns (address);

	function setAddr(bytes32 node, address addr_) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.0;

interface RegistrarInterface {
	event OwnerChanged(
		bytes32 indexed label,
		address indexed oldOwner,
		address indexed newOwner
	);
	event DomainConfigured(bytes32 indexed label);
	event DomainUnlisted(bytes32 indexed label);
	event NewRegistration(
		bytes32 indexed label,
		string subdomain,
		address indexed owner,
		uint256 expires
	);
	event RentPaid(
		bytes32 indexed label,
		string subdomain,
		uint256 amount,
		uint256 expirationDate
	);

	// InterfaceID of these four methods is 0xc1b15f5a
	function query(bytes32 label, string calldata subdomain)
		external
		view
		returns (
			string memory domain,
			uint256 signupFee,
			uint256 rent,
			address referralAddress
		);

	function register(
		bytes32 label,
		string calldata subdomain,
		address owner,
		uint256 duration,
		string calldata url,
		address resolver
	) external payable;

	function rentDue(bytes32 label, string calldata subdomain)
		external
		view
		returns (uint256 timestamp);

	function payRent(bytes32 label, string calldata subdomain) external payable;

	function rentPrice(string memory name, uint256 duration)
		external
		view
		returns (uint256);
}