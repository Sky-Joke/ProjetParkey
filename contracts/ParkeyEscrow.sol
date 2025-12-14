// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title ParkeyEscrow
 * @dev Gestion sécurisée des paiements avec système d'escrow
 * Les fonds sont bloqués jusqu'à confirmation de la prestation
 */
contract ParkeyEscrow is Ownable, ReentrancyGuard {
    
    enum PaymentStatus {
        Pending,        // En attente
        Released,       // Libéré au bénéficiaire
        Refunded,       // Remboursé au payeur
        Disputed        // En litige
    }
    
    enum DisputeStatus {
        None,           // Pas de litige
        Open,           // Litige ouvert
        Resolved        // Litige résolu
    }
    
    // Structure d'un paiement en escrow
    struct EscrowPayment {
        uint256 paymentId;
        address payer;              // Celui qui paie (locataire)
        address payee;              // Celui qui reçoit (propriétaire)
        uint256 amount;             // Montant total
        uint256 releaseTime;        // Date de libération automatique
        uint256 createdAt;          // Date de création
        PaymentStatus status;       // Statut du paiement
        string refData;           // Référence (ex: reservationId)
        bool autoRelease;           // Libération automatique activée
    }
    
    // Structure d'un litige
    struct Dispute {
        uint256 disputeId;
        uint256 paymentId;
        address initiator;          // Qui a ouvert le litige
        string reason;              // Raison du litige
        DisputeStatus status;
        address resolver;           // Qui a résolu le litige
        string resolution;          // Résolution du litige
        uint256 refundPercentage;   // % de remboursement (0-100)
        uint256 createdAt;
        uint256 resolvedAt;
    }
    
    // Mappings
    mapping(uint256 => EscrowPayment) public payments;
    mapping(uint256 => Dispute) public disputes;
    mapping(address => uint256[]) public userPayments;
    mapping(string => uint256) public referenceToPaymentId; // reference => paymentId
    
    // Compteurs
    uint256 public paymentCounter;
    uint256 public disputeCounter;
    
    // Adresses autorisées à créer des escrows (contrats de réservation)
    mapping(address => bool) public authorizedContracts;
    
    // Paramètres
    uint256 public disputeTimeWindow = 7 days; // Délai pour ouvrir un litige après release time
    uint256 public autoReleaseDelay = 1 hours; // Délai après endTime pour auto-release
    
    // Events
    event PaymentCreated(
        uint256 indexed paymentId,
        address indexed payer,
        address indexed payee,
        uint256 amount,
        string ref
    );
    
    event PaymentReleased(
        uint256 indexed paymentId,
        address indexed payee,
        uint256 amount
    );
    
    event PaymentRefunded(
        uint256 indexed paymentId,
        address indexed payer,
        uint256 amount
    );
    
    event DisputeCreated(
        uint256 indexed disputeId,
        uint256 indexed paymentId,
        address indexed initiator,
        string reason
    );
    
    event DisputeResolved(
        uint256 indexed disputeId,
        uint256 indexed paymentId,
        uint256 refundPercentage
    );
    
    event AutoReleaseExecuted(
        uint256 indexed paymentId,
        uint256 amount
    );

    constructor() Ownable(msg.sender) {
        // Le déployeur est automatiquement autorisé
        authorizedContracts[msg.sender] = true;
    }

    modifier onlyAuthorized() {
        require(
            authorizedContracts[msg.sender] || msg.sender == owner(),
            "Non autorise"
        );
        _;
    }

    /**
     * @dev Créer un paiement en escrow
     */
    function createPayment(
        address _payer,
        address _payee,
        uint256 _releaseTime,
        string memory _reference,
        bool _autoRelease
    ) external payable onlyAuthorized returns (uint256) {
        require(_payee != address(0), "Adresse beneficiaire invalide");
        require(msg.value > 0, "Montant doit etre superieur a 0");
        require(_releaseTime > block.timestamp, "Release time doit etre dans le futur");
        require(bytes(_reference).length > 0, "Reference requise");
        require(referenceToPaymentId[_reference] == 0, "Reference deja utilisee");
        
        uint256 paymentId = paymentCounter++;
        
        payments[paymentId] = EscrowPayment({
            paymentId: paymentId,
            payer: _payer,
            payee: _payee,
            amount: msg.value,
            releaseTime: _releaseTime,
            createdAt: block.timestamp,
            status: PaymentStatus.Pending,
            refData: _reference,
            autoRelease: _autoRelease
        });
        
        userPayments[_payer].push(paymentId);
        userPayments[_payee].push(paymentId);
        referenceToPaymentId[_reference] = paymentId;
        
        emit PaymentCreated(paymentId, _payer, _payee, msg.value, _reference);
        
        return paymentId;
    }

    /**
     * @dev Libérer un paiement au bénéficiaire
     * Peut être appelé par le payeur, le payee, ou automatiquement
     */
    function releasePayment(uint256 _paymentId) external nonReentrant {
        EscrowPayment storage payment = payments[_paymentId];
        
        require(payment.status == PaymentStatus.Pending, "Paiement deja traite");
        require(
            msg.sender == payment.payer || 
            msg.sender == payment.payee || 
            authorizedContracts[msg.sender] ||
            msg.sender == owner(),
            "Non autorise"
        );
        
        // Vérifier que le release time est passé
        require(block.timestamp >= payment.releaseTime, "Trop tot pour liberer");
        
        payment.status = PaymentStatus.Released;
        
        payable(payment.payee).transfer(payment.amount);
        
        emit PaymentReleased(_paymentId, payment.payee, payment.amount);
    }

    /**
     * @dev Libération automatique après le délai
     */
    function autoReleasePayment(uint256 _paymentId) external nonReentrant {
        EscrowPayment storage payment = payments[_paymentId];
        
        require(payment.status == PaymentStatus.Pending, "Paiement deja traite");
        require(payment.autoRelease, "Auto-release non active");
        require(
            block.timestamp >= payment.releaseTime + autoReleaseDelay,
            "Delai auto-release non atteint"
        );
        
        payment.status = PaymentStatus.Released;
        
        payable(payment.payee).transfer(payment.amount);
        
        emit AutoReleaseExecuted(_paymentId, payment.amount);
        emit PaymentReleased(_paymentId, payment.payee, payment.amount);
    }

    /**
     * @dev Rembourser un paiement au payeur
     * Uniquement par les contrats autorisés ou owner
     */
    function refundPayment(uint256 _paymentId) external nonReentrant onlyAuthorized {
        EscrowPayment storage payment = payments[_paymentId];
        
        require(payment.status == PaymentStatus.Pending, "Paiement deja traite");
        
        payment.status = PaymentStatus.Refunded;
        
        payable(payment.payer).transfer(payment.amount);
        
        emit PaymentRefunded(_paymentId, payment.payer, payment.amount);
    }

    /**
     * @dev Ouvrir un litige sur un paiement
     */
    function openDispute(
        uint256 _paymentId,
        string memory _reason
    ) external returns (uint256) {
        EscrowPayment storage payment = payments[_paymentId];
        
        require(payment.status == PaymentStatus.Pending, "Paiement deja traite");
        require(
            msg.sender == payment.payer || msg.sender == payment.payee,
            "Seules les parties peuvent ouvrir un litige"
        );
        require(
            block.timestamp <= payment.releaseTime + disputeTimeWindow,
            "Delai pour ouvrir un litige depasse"
        );
        require(bytes(_reason).length > 0, "Raison requise");
        
        // Vérifier qu'il n'y a pas déjà un litige ouvert
        for (uint256 i = 0; i < disputeCounter; i++) {
            if (disputes[i].paymentId == _paymentId && 
                disputes[i].status == DisputeStatus.Open) {
                revert("Un litige existe deja");
            }
        }
        
        payment.status = PaymentStatus.Disputed;
        
        uint256 disputeId = disputeCounter++;
        
        disputes[disputeId] = Dispute({
            disputeId: disputeId,
            paymentId: _paymentId,
            initiator: msg.sender,
            reason: _reason,
            status: DisputeStatus.Open,
            resolver: address(0),
            resolution: "",
            refundPercentage: 0,
            createdAt: block.timestamp,
            resolvedAt: 0
        });
        
        emit DisputeCreated(disputeId, _paymentId, msg.sender, _reason);
        
        return disputeId;
    }

    /**
     * @dev Résoudre un litige (owner only)
     * @param _refundPercentage Pourcentage à rembourser au payeur (0-100)
     */
    function resolveDispute(
        uint256 _disputeId,
        uint256 _refundPercentage,
        string memory _resolution
    ) external onlyOwner nonReentrant {
        Dispute storage dispute = disputes[_disputeId];
        require(dispute.status == DisputeStatus.Open, "Litige non ouvert");
        require(_refundPercentage <= 100, "Pourcentage invalide");
        require(bytes(_resolution).length > 0, "Resolution requise");
        
        EscrowPayment storage payment = payments[dispute.paymentId];
        require(payment.status == PaymentStatus.Disputed, "Paiement non en litige");
        
        dispute.status = DisputeStatus.Resolved;
        dispute.resolver = msg.sender;
        dispute.resolution = _resolution;
        dispute.refundPercentage = _refundPercentage;
        dispute.resolvedAt = block.timestamp;
        
        // Calculer les montants
        uint256 refundAmount = (payment.amount * _refundPercentage) / 100;
        uint256 releaseAmount = payment.amount - refundAmount;
        
        // Effectuer les transferts
        if (refundAmount > 0) {
            payment.status = PaymentStatus.Refunded;
            payable(payment.payer).transfer(refundAmount);
            emit PaymentRefunded(dispute.paymentId, payment.payer, refundAmount);
        }
        
        if (releaseAmount > 0) {
            payment.status = PaymentStatus.Released;
            payable(payment.payee).transfer(releaseAmount);
            emit PaymentReleased(dispute.paymentId, payment.payee, releaseAmount);
        }
        
        emit DisputeResolved(_disputeId, dispute.paymentId, _refundPercentage);
    }

    /**
     * @dev Obtenir les paiements d'un utilisateur
     */
    function getUserPayments(address _user) external view returns (uint256[] memory) {
        return userPayments[_user];
    }

    /**
     * @dev Obtenir un paiement par sa référence
     */
    function getPaymentByReference(string memory _reference) external view returns (EscrowPayment memory) {
        uint256 paymentId = referenceToPaymentId[_reference];
        require(paymentId > 0 || keccak256(bytes(payments[0].refData)) == keccak256(bytes(_reference)), "Reference non trouvee");
        return payments[paymentId];
    }

    /**
     * @dev Vérifier si un paiement peut être libéré
     */
    function canRelease(uint256 _paymentId) external view returns (bool) {
        EscrowPayment memory payment = payments[_paymentId];
        return payment.status == PaymentStatus.Pending && 
               block.timestamp >= payment.releaseTime;
    }

    /**
     * @dev Vérifier si un paiement peut être auto-libéré
     */
    function canAutoRelease(uint256 _paymentId) external view returns (bool) {
        EscrowPayment memory payment = payments[_paymentId];
        return payment.status == PaymentStatus.Pending && 
               payment.autoRelease &&
               block.timestamp >= payment.releaseTime + autoReleaseDelay;
    }

    /**
     * @dev Autoriser un contrat à créer des escrows
     */
    function authorizeContract(address _contract) external onlyOwner {
        require(_contract != address(0), "Adresse invalide");
        authorizedContracts[_contract] = true;
    }

    /**
     * @dev Révoquer l'autorisation d'un contrat
     */
    function revokeContract(address _contract) external onlyOwner {
        authorizedContracts[_contract] = false;
    }

    /**
     * @dev Modifier le délai de litige
     */
    function setDisputeTimeWindow(uint256 _newWindow) external onlyOwner {
        require(_newWindow >= 1 days && _newWindow <= 30 days, "Delai invalide");
        disputeTimeWindow = _newWindow;
    }

    /**
     * @dev Modifier le délai d'auto-release
     */
    function setAutoReleaseDelay(uint256 _newDelay) external onlyOwner {
        require(_newDelay >= 1 hours && _newDelay <= 7 days, "Delai invalide");
        autoReleaseDelay = _newDelay;
    }

    /**
     * @dev Récupérer les fonds en cas d'urgence (owner only)
     */
    function emergencyWithdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    /**
     * @dev Obtenir le solde du contrat
     */
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}