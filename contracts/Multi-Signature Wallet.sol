// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title Multi-Signature Wallet
 * @dev A secure wallet that requires multiple signatures to execute transactions
 * @author Multi-Sig Wallet Team
 */
contract Project {
    // Events
    event TransactionSubmitted(uint256 indexed txId, address indexed submitter, address indexed to, uint256 value);
    event TransactionApproved(uint256 indexed txId, address indexed approver);
    event TransactionExecuted(uint256 indexed txId, address indexed executor);
    event OwnerAdded(address indexed newOwner);
    event OwnerRemoved(address indexed removedOwner);
    event RequiredSignaturesChanged(uint256 newRequiredSignatures);

    // State variables
    address[] public owners;
    mapping(address => bool) public isOwner;
    uint256 public requiredSignatures;
    
    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool executed;
        uint256 approvalCount;
        mapping(address => bool) approved;
    }
    
    mapping(uint256 => Transaction) public transactions;
    uint256 public transactionCount;

    // Modifiers
    modifier onlyOwner() {
        require(isOwner[msg.sender], "Not an owner");
        _;
    }
    
    modifier txExists(uint256 _txId) {
        require(_txId < transactionCount, "Transaction does not exist");
        _;
    }
    
    modifier notExecuted(uint256 _txId) {
        require(!transactions[_txId].executed, "Transaction already executed");
        _;
    }
    
    modifier notApproved(uint256 _txId) {
        require(!transactions[_txId].approved[msg.sender], "Transaction already approved by sender");
        _;
    }

    /**
     * @dev Constructor to initialize the multi-sig wallet
     * @param _owners Array of owner addresses (e.g., ["0x123...", "0x456...", "0x789..."])
     * @param _requiredSignatures Number of required signatures for transaction execution (e.g., 2)
     */
    constructor(address[] memory _owners, uint256 _requiredSignatures) {
        require(_owners.length > 0, "Owners required");
        require(_requiredSignatures > 0 && _requiredSignatures <= _owners.length, "Invalid required signatures count");
        
        for (uint256 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];
            require(owner != address(0), "Invalid owner address");
            require(!isOwner[owner], "Owner not unique");
            
            isOwner[owner] = true;
            owners.push(owner);
        }
        
        requiredSignatures = _requiredSignatures;
    }

    /**
     * @dev Core Function 1: Submit a new transaction for approval
     * @param _to Destination address
     * @param _value Amount of Ether to send
     * @param _data Transaction data
     * @return Transaction ID
     */
    function submitTransaction(address _to, uint256 _value, bytes memory _data) 
        public 
        onlyOwner 
        returns (uint256) 
    {
        uint256 txId = transactionCount;
        
        Transaction storage newTx = transactions[txId];
        newTx.to = _to;
        newTx.value = _value;
        newTx.data = _data;
        newTx.executed = false;
        newTx.approvalCount = 0;
        
        transactionCount++;
        
        emit TransactionSubmitted(txId, msg.sender, _to, _value);
        return txId;
    }

    /**
     * @dev Core Function 2: Approve a submitted transaction
     * @param _txId Transaction ID to approve
     */
    function approveTransaction(uint256 _txId) 
        public 
        onlyOwner 
        txExists(_txId) 
        notExecuted(_txId) 
        notApproved(_txId) 
    {
        Transaction storage transaction = transactions[_txId];
        transaction.approved[msg.sender] = true;
        transaction.approvalCount++;
        
        emit TransactionApproved(_txId, msg.sender);
    }

    /**
     * @dev Core Function 3: Execute an approved transaction
     * @param _txId Transaction ID to execute
     */
    function executeTransaction(uint256 _txId) 
        public 
        onlyOwner 
        txExists(_txId) 
        notExecuted(_txId) 
    {
        Transaction storage transaction = transactions[_txId];
        require(transaction.approvalCount >= requiredSignatures, "Not enough approvals");
        
        transaction.executed = true;
        
        (bool success, ) = transaction.to.call{value: transaction.value}(transaction.data);
        require(success, "Transaction execution failed");
        
        emit TransactionExecuted(_txId, msg.sender);
    }

    /**
     * @dev Get transaction details
     * @param _txId Transaction ID
     * @return to, value, data, executed, approvalCount
     */
    function getTransaction(uint256 _txId) 
        public 
        view 
        txExists(_txId) 
        returns (address, uint256, bytes memory, bool, uint256) 
    {
        Transaction storage transaction = transactions[_txId];
        return (
            transaction.to,
            transaction.value,
            transaction.data,
            transaction.executed,
            transaction.approvalCount
        );
    }

    /**
     * @dev Check if a transaction is approved by a specific owner
     * @param _txId Transaction ID
     * @param _owner Owner address
     * @return Approval status
     */
    function isApproved(uint256 _txId, address _owner) 
        public 
        view 
        txExists(_txId) 
        returns (bool) 
    {
        return transactions[_txId].approved[_owner];
    }

    /**
     * @dev Get all owners
     * @return Array of owner addresses
     */
    function getOwners() public view returns (address[] memory) {
        return owners;
    }

    /**
     * @dev Get contract balance
     * @return Contract balance in wei
     */
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev Receive function to accept Ether deposits
     */
    receive() external payable {}

    /**
     * @dev Fallback function
     */
    fallback() external payable {}
}
