pragma solidity ^0.8.0;

contract MicroFinancing {
    struct Document {
        uint256 id;
        string title;
        string content;
        string documentHash;
    }

    struct FinancialDetails {
        uint256 documentId;
        uint256 loanAmount;
        uint256 interestRate;
        uint256 repaymentPeriod;
        uint256 startTime;
    }

    mapping(uint256 => Document) public documents;
    mapping(uint256 => FinancialDetails) public financialDetailsMapping;
    uint256[] public documentIds;

    function addDocument(
        string memory _title,
        string memory _content,
        string memory _documentHash
    ) public {
        uint256 newDocumentId = documentIds.length + 1;
        Document memory newDocument = Document(newDocumentId, _title, _content, _documentHash);
        documents[newDocumentId] = newDocument;
        documentIds.push(newDocumentId);
    }

    function addFinancialDetails(
        uint256 _documentId,
        uint256 _loanAmount,
        uint256 _interestRate,
        uint256 _repaymentPeriod
    ) public {
        FinancialDetails memory newDetails = FinancialDetails(
            _documentId,
            _loanAmount,
            _interestRate,
            _repaymentPeriod,
            block.timestamp
        );
        financialDetailsMapping[_documentId] = newDetails;
    }

    function getDocument(uint256 _documentId) public view returns (Document memory) {
        return documents[_documentId];
    }

    function getFinancialDetails(uint256 _documentId)
        public
        view
        returns (FinancialDetails memory)
    {
        return financialDetailsMapping[_documentId];
    }

    function updateDocument(
        uint256 _documentId,
        string memory _title,
        string memory _content,
        string memory _documentHash
    ) public {
        Document storage document = documents[_documentId];
        document.title = _title;
        document.content = _content;
        document.documentHash = _documentHash;
    }

    function updateFinancialDetails(
        uint256 _documentId,
        uint256 _loanAmount,
        uint256 _interestRate,
        uint256 _repaymentPeriod
    ) public {
        FinancialDetails storage details = financialDetailsMapping[_documentId];
        details.loanAmount = _loanAmount;
        details.interestRate = _interestRate;
        details.repaymentPeriod = _repaymentPeriod;
    }
}