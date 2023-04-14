//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.19;

contract BaworCashflow {
	address _contractOwner;

	mapping(address => bool) _contractOperators;
	address[] nftAddresses;
	mapping(address => Project) projects;
	mapping(address => ProjectTransaction[]) projectTransactions;

	struct Project {
		address nftAddress;
		string name;
		string uri;
		uint256 totalSupply;
		uint256 maxSupply;
		uint256 totalCredit;
		uint256 totalDebit;
		uint256 balance;
		uint256 totalOwner;
	}

	struct ProjectTransaction {
		uint256 date;
		string description;
		uint256 credit;
		uint256 debit;
		uint256 balance;
		uint256 dateCreated;
	}

	modifier onlyContractOwner() {
		require(msg.sender == _contractOwner, "Hanya Pemilik contract yang bisa melakukan aksi ini.");
		_;
	}

	modifier onlyOperator() {
		require(_contractOperators[msg.sender] == true, "Hanya Operator contract yang bisa melakukan aksi ini.");
		_;
	}

	constructor(address[] memory operators) {
		_contractOwner = msg.sender;
		for (uint256 i = 0; i < operators.length; i++) {
			_contractOperators[operators[i]] = true;
		}
	}

	function addOperator(address operator) public onlyOperator {
		_contractOperators[operator] = true;
	}

	function deActivateOperator(address operator) public onlyOperator {
		_contractOperators[operator] = false;
	}

	function isOperator(address operator) public view returns (bool) {
		return _contractOperators[operator] == true;
	}

	function addProject(address nftAddress, string memory name, string memory uri, uint256 date, uint256 initialBalance) public onlyOperator {
		require(bytes(name).length > 0, "Silahkan isi nama project Anda.");
		require(bytes(uri).length > 0, "Silahkan isi uri atau metadata project Anda.");
		require(date > 0, "Silahkan isi Tanggal Modal Awal project Anda.");
		require(!isNFTAddressValid(nftAddress), "NFT Address sudah terdaftar.");

		projects[nftAddress] = Project(nftAddress, name, uri, 0, 200, initialBalance, 0, initialBalance, 0);
		projectTransactions[nftAddress].push(ProjectTransaction(date, "Modal Awal", initialBalance, 0, initialBalance, block.timestamp));

		nftAddresses.push(nftAddress);
	}

	function updateProject(address nftAddress, string memory name, string memory uri) public onlyOperator {
		require(isNFTAddressValid(nftAddress), "Project tidak ditemukan");
		require(bytes(name).length > 0, "Silahkan isi nama project Anda.");
		require(bytes(uri).length > 0, "Silahkan isi uri atau metadata project Anda.");

		projects[nftAddress].name = name;
		projects[nftAddress].uri = uri;
	}

	function getProjects() public view returns (Project[] memory) {
		Project[] memory result = new Project[](nftAddresses.length);
		for (uint i = 0; i < nftAddresses.length; i++) {
			result[i] = projects[nftAddresses[i]];
		}
		return result;
	}

	function getProject(address nftAddress) external view returns (Project memory) {
		require(isNFTAddressValid(nftAddress), "Project tidak ditemukan");
		return projects[nftAddress];
	}

	function addTransactionCredit(address nftAddress, uint256 date, string memory description, uint256 credit) public onlyOperator {
		require(isNFTAddressValid(nftAddress), "Project tidak ditemukan");
		require(date > 0, "Silahkan isi Tanggal transaksi Anda.");
		require(bytes(description).length > 0, "Silahkan isi deskripsi transaksi Anda.");
		require(credit > 0, "Nilai Kredit harus lebih besar dari 0.");

		uint256 lastBalance = projects[nftAddress].balance;
		uint256 newLastBalance = lastBalance + credit;
		ProjectTransaction memory newTransaction = ProjectTransaction(date, description, credit, 0, newLastBalance, block.timestamp);
		projectTransactions[nftAddress].push(newTransaction);

		projects[nftAddress].totalCredit = projects[nftAddress].totalCredit + credit;
		projects[nftAddress].balance = newLastBalance;
	}

	function addTransactionDebit(address nftAddress, uint256 date, string memory description, uint256 debit) public onlyOperator {
		require(isNFTAddressValid(nftAddress), "Project tidak ditemukan");
		require(date > 0, "Silahkan isi Tanggal transaksi Anda.");
		require(bytes(description).length > 0, "Silahkan isi deskripsi transaksi Anda.");
		require(debit > 0, "Nilai Debit harus lebih besar dari 0.");

		uint256 lastBalance = projects[nftAddress].balance;
		uint256 newLastBalance = lastBalance - debit;
		projectTransactions[nftAddress].push(ProjectTransaction(date, description, 0, debit, newLastBalance, block.timestamp));

		projects[nftAddress].totalDebit = projects[nftAddress].totalDebit + debit;
		projects[nftAddress].balance = newLastBalance;
	}

	function getProjectTransactions(address nftAddress) public view returns (ProjectTransaction[] memory) {
		require(isNFTAddressValid(nftAddress), "Project tidak ditemukan");
		ProjectTransaction[] memory result = new ProjectTransaction[](projectTransactions[nftAddress].length);
		for (uint i = 0; i < projectTransactions[nftAddress].length; i++) {
			result[i] = projectTransactions[nftAddress][i];
		}
		return result;
	}

	function getProjectTransactionByDate(address nftAddress, uint256 dateFrom) public view returns (ProjectTransaction[] memory) {
		require(isNFTAddressValid(nftAddress), "Project tidak ditemukan");
		ProjectTransaction[] memory result = new ProjectTransaction[](projectTransactions[nftAddress].length);
		uint256 resultIndex = 0;
		for (uint256 i = 0; i < projectTransactions[nftAddress].length; i++) {
			if (projectTransactions[nftAddress][i].date >= dateFrom) {
				result[resultIndex] = projectTransactions[nftAddress][i];
				resultIndex++;
			}
		}
		// Resize result array to exclude unused elements
		assembly {
			mstore(result, resultIndex)
		}
		return result;
	}

	function getLastProjectTransaction(address nftAddress) public view returns (ProjectTransaction memory) {
		require(isNFTAddressValid(nftAddress), "Project tidak ditemukan");
		uint256 lastIndex = projectTransactions[nftAddress].length - 1;
		return projectTransactions[nftAddress][lastIndex];
	}

	function getProjectTransactionAtIndex(address nftAddress, uint256 index) public view returns (ProjectTransaction[] memory) {
		require(isNFTAddressValid(nftAddress), "Project tidak ditemukan");
		ProjectTransaction[] memory result = new ProjectTransaction[](projectTransactions[nftAddress].length);

		uint256 startIndex = projectTransactions[nftAddress].length - index;
		if (startIndex < 0) startIndex = 0;

		uint256 resultIndex = 0;
		for (uint256 i = startIndex; i < projectTransactions[nftAddress].length; i++) {
			result[resultIndex] = projectTransactions[nftAddress][i];
			resultIndex++;
		}
		// Resize result array to exclude unused elements
		assembly {
			mstore(result, resultIndex)
		}
		return result;
	}

	// function getProjectByToken(uint256 tokenId) public view returns (Project memory) {
	// 	require(tokenId > 0 && tokenId <= _tokendIds.current(), "Token tidak ditemukan.");
	// 	return projects[_tokenProjects[tokenId]];
	// }

	function isNFTAddressValid(address nftAddress) public view returns (bool) {
		for (uint256 i = 0; i < nftAddresses.length; i++) {
			if (nftAddresses[i] == nftAddress) {
				return true;
			}
		}
		return false;
	}
}