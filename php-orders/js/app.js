/**
 * TioRes - Customer Ordering System
 * Optimized JavaScript Module
 */

const TioRes = (() => {
    // Configuration
    const API_BASE = 'api';

    // State
    let state = {
        tableId: null,
        tableName: '',
        orderId: null,
        tierId: null,
        cart: [],
        menuItems: [],
        categories: [],
        selectedCategory: 'all',
        modalItem: null,
        modalQty: 1
    };

    // Get URL params
    const getParams = () => {
        const params = new URLSearchParams(window.location.search);
        return {
            tableId: params.get('table') || params.get('t'),
            tableName: params.get('name') || params.get('n'),
            tierId: params.get('tier'),
            orderId: params.get('order')
        };
    };

    // Initialize (Menu Page)
    const init = async () => {
        const params = getParams();
        state.tableId = params.tableId || localStorage.getItem('tableId');
        state.tableName = params.tableName || localStorage.getItem('tableName') || state.tableId;
        state.tierId = params.tierId || localStorage.getItem('tierId');
        state.orderId = params.orderId || localStorage.getItem('orderId');

        // Save to localStorage
        if (state.tableId) localStorage.setItem('tableId', state.tableId);
        if (state.tableName) localStorage.setItem('tableName', state.tableName);
        if (state.tierId) localStorage.setItem('tierId', state.tierId);
        if (state.orderId) localStorage.setItem('orderId', state.orderId);

        // Load cart from localStorage
        state.cart = JSON.parse(localStorage.getItem('cart') || '[]');

        // Update UI
        updateTableBadge();
        updateCartButton();

        // Load menu
        await loadMenu();
    };

    // Load Menu Items
    const loadMenu = async () => {
        const loading = document.getElementById('loading');
        const menuGrid = document.getElementById('menu-grid');
        const emptyState = document.getElementById('empty-state');

        try {
            const url = `${API_BASE}/get_items.php?tier_id=${state.tierId || ''}`;
            const response = await fetch(url);
            const data = await response.json();

            if (!data.success) throw new Error(data.error);

            state.menuItems = data.items;
            state.categories = data.categories;

            loading.classList.add('hidden');

            if (state.menuItems.length === 0) {
                emptyState.classList.remove('hidden');
                emptyState.classList.add('flex');
                return;
            }

            renderCategories();
            renderMenuItems();

        } catch (error) {
            console.error('Failed to load menu:', error);
            loading.innerHTML = `
                <p class="text-accent">เกิดข้อผิดพลาด</p>
                <p class="text-white/50 mt-2 text-sm">${error.message}</p>
                <button onclick="location.reload()" class="mt-4 px-6 py-2 bg-primary/20 text-primary rounded-xl">ลองใหม่</button>
            `;
        }
    };

    // Render Categories
    const renderCategories = () => {
        const container = document.getElementById('category-tabs');
        const allBtn = container.querySelector('[data-category="all"]');

        state.categories.forEach(cat => {
            const btn = document.createElement('button');
            btn.dataset.category = cat.id;
            btn.className = 'category-btn whitespace-nowrap px-4 py-2 rounded-full text-sm bg-dark-700 text-white/70 border border-white/10 hover:bg-dark-600 transition';
            btn.textContent = cat.name;
            btn.onclick = () => selectCategory(cat.id);
            container.appendChild(btn);
        });

        allBtn.onclick = () => selectCategory('all');
    };

    // Select Category
    const selectCategory = (catId) => {
        state.selectedCategory = catId;

        // Update active state
        document.querySelectorAll('.category-btn').forEach(btn => {
            const isActive = btn.dataset.category == catId;
            btn.classList.toggle('active', isActive);
            btn.classList.toggle('bg-primary/20', isActive);
            btn.classList.toggle('text-primary', isActive);
            btn.classList.toggle('border-primary/30', isActive);
            btn.classList.toggle('bg-dark-700', !isActive);
            btn.classList.toggle('text-white/70', !isActive);
        });

        renderMenuItems();
    };

    // Render Menu Items
    const renderMenuItems = () => {
        const container = document.getElementById('menu-grid');
        const emptyState = document.getElementById('empty-state');

        const filtered = state.selectedCategory === 'all'
            ? state.menuItems
            : state.menuItems.filter(item => item.category_id == state.selectedCategory);

        if (filtered.length === 0) {
            container.innerHTML = '';
            emptyState.classList.remove('hidden');
            emptyState.classList.add('flex');
            return;
        }

        emptyState.classList.add('hidden');
        emptyState.classList.remove('flex');

        container.innerHTML = filtered.map(item => `
            <div class="menu-card bg-dark-800 rounded-2xl overflow-hidden border border-white/10 cursor-pointer" onclick="TioRes.openModal(${item.id})">
                <div class="h-32 bg-dark-700 bg-cover bg-center" style="background-image: url('${item.image_url || 'https://via.placeholder.com/300x200/21262D/666?text=No+Image'}')"></div>
                <div class="p-4">
                    <h3 class="font-medium text-sm line-clamp-2 mb-2">${item.name}</h3>
                    <div class="flex items-center justify-between">
                        <span class="text-primary font-bold">฿${formatNumber(item.price)}</span>
                        <button class="w-8 h-8 bg-primary/20 text-primary rounded-full flex items-center justify-center hover:bg-primary/30 transition">
                            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/>
                            </svg>
                        </button>
                    </div>
                </div>
            </div>
        `).join('');
    };

    // Open Add Modal
    const openModal = (itemId) => {
        const item = state.menuItems.find(i => i.id == itemId);
        if (!item) return;

        state.modalItem = item;
        state.modalQty = 1;

        document.getElementById('modal-image').style.backgroundImage = `url('${item.image_url || 'https://via.placeholder.com/400x200/21262D/666?text=No+Image'}')`;
        document.getElementById('modal-name').textContent = item.name;
        document.getElementById('modal-price').textContent = `฿${formatNumber(item.price)}`;
        document.getElementById('modal-qty').textContent = state.modalQty;
        document.getElementById('modal-notes').value = '';

        const modal = document.getElementById('add-modal');
        modal.classList.remove('hidden');
        modal.classList.add('flex');
    };

    // Close Modal
    window.closeModal = () => {
        const modal = document.getElementById('add-modal');
        modal.classList.add('hidden');
        modal.classList.remove('flex');
        state.modalItem = null;
    };

    // Change Quantity
    window.changeQty = (delta) => {
        state.modalQty = Math.max(1, state.modalQty + delta);
        document.getElementById('modal-qty').textContent = state.modalQty;
    };

    // Add to Cart
    window.addToCart = () => {
        if (!state.modalItem) return;

        const notes = document.getElementById('modal-notes').value.trim();

        // Check if already in cart
        const existing = state.cart.find(c => c.item_id == state.modalItem.id && c.notes == notes);

        if (existing) {
            existing.quantity += state.modalQty;
        } else {
            state.cart.push({
                item_id: state.modalItem.id,
                name: state.modalItem.name,
                price: state.modalItem.price,
                quantity: state.modalQty,
                notes: notes,
                status: 'pending'
            });
        }

        // Save to localStorage
        localStorage.setItem('cart', JSON.stringify(state.cart));

        // Update UI
        updateCartButton();
        closeModal();
        showToast(`เพิ่ม ${state.modalItem.name} แล้ว`);
    };

    // Update Cart Button
    const updateCartButton = () => {
        const btn = document.getElementById('cart-button');
        const countEl = document.getElementById('cart-count');
        const totalEl = document.getElementById('cart-total');

        if (!btn) return;

        const pendingItems = state.cart.filter(c => c.status === 'pending');
        const count = pendingItems.reduce((sum, c) => sum + c.quantity, 0);
        const total = pendingItems.reduce((sum, c) => sum + (c.price * c.quantity), 0);

        if (count > 0) {
            btn.classList.remove('hidden');
            btn.classList.add('cart-pulse');
            countEl.textContent = count;
            totalEl.textContent = formatNumber(total);
        } else {
            btn.classList.add('hidden');
        }
    };

    // Update Table Badge
    const updateTableBadge = () => {
        const el = document.getElementById('table-name');
        if (el) el.textContent = state.tableName || '-';
    };

    // Show Toast
    const showToast = (message) => {
        const toast = document.createElement('div');
        toast.className = 'toast fixed bottom-24 left-1/2 -translate-x-1/2 bg-dark-700 text-white px-6 py-3 rounded-full border border-white/10 shadow-lg z-50';
        toast.textContent = message;
        document.body.appendChild(toast);
        setTimeout(() => toast.remove(), 3000);
    };

    // Format Number
    const formatNumber = (num) => {
        return Number(num).toLocaleString('th-TH');
    };

    // ==================== ORDERS PAGE ====================

    const initOrdersPage = () => {
        const params = getParams();
        state.tableId = localStorage.getItem('tableId');
        state.tableName = localStorage.getItem('tableName');
        state.cart = JSON.parse(localStorage.getItem('cart') || '[]');

        updateTableBadge();
        renderOrderItems();
    };

    const renderOrderItems = () => {
        const pendingList = document.getElementById('pending-list');
        const sentList = document.getElementById('sent-list');
        const emptyState = document.getElementById('empty-state');
        const actionBar = document.getElementById('action-bar');
        const sentSection = document.getElementById('sent-section');

        const pending = state.cart.filter(c => c.status === 'pending');
        const sent = state.cart.filter(c => c.status === 'sent');

        if (state.cart.length === 0) {
            emptyState.classList.remove('hidden');
            emptyState.classList.add('flex');
            actionBar.classList.add('hidden');
            return;
        }

        emptyState.classList.add('hidden');
        emptyState.classList.remove('flex');

        // Render pending
        if (pending.length > 0) {
            actionBar.classList.remove('hidden');
            document.getElementById('pending-count').textContent = `${pending.length} รายการ`;
            document.getElementById('subtotal').textContent = formatNumber(
                pending.reduce((sum, c) => sum + (c.price * c.quantity), 0)
            );

            pendingList.innerHTML = pending.map((item, idx) => `
                <div class="order-item bg-dark-800 rounded-xl p-4 border border-white/10 flex items-center gap-4">
                    <div class="flex-1">
                        <h4 class="font-medium">${item.name}</h4>
                        ${item.notes ? `<p class="text-sm text-white/50 mt-1">${item.notes}</p>` : ''}
                    </div>
                    <div class="flex items-center gap-3">
                        <button onclick="TioRes.changeCartQty(${idx}, -1)" class="w-8 h-8 bg-dark-700 rounded-full flex items-center justify-center">−</button>
                        <span class="w-6 text-center font-bold">${item.quantity}</span>
                        <button onclick="TioRes.changeCartQty(${idx}, 1)" class="w-8 h-8 bg-primary/20 text-primary rounded-full flex items-center justify-center">+</button>
                    </div>
                    <div class="text-right min-w-[80px]">
                        <p class="font-bold text-primary">฿${formatNumber(item.price * item.quantity)}</p>
                    </div>
                    <button onclick="TioRes.removeFromCart(${idx})" class="w-8 h-8 text-accent/60 hover:text-accent transition">
                        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
                        </svg>
                    </button>
                </div>
            `).join('');
        } else {
            actionBar.classList.add('hidden');
            pendingList.innerHTML = '';
        }

        // Render sent
        if (sent.length > 0) {
            sentSection.classList.remove('hidden');
            document.getElementById('sent-count').textContent = `${sent.length} รายการ`;
            sentList.innerHTML = sent.map(item => `
                <div class="bg-dark-800/50 rounded-xl p-4 border border-success/20 flex items-center gap-4">
                    <div class="w-6 h-6 bg-success/20 rounded-full flex items-center justify-center">
                        <svg class="w-4 h-4 text-success" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/>
                        </svg>
                    </div>
                    <div class="flex-1">
                        <h4 class="font-medium">${item.name}</h4>
                        ${item.notes ? `<p class="text-sm text-white/50">${item.notes}</p>` : ''}
                    </div>
                    <span class="font-medium">x${item.quantity}</span>
                    <span class="text-white/50">฿${formatNumber(item.price * item.quantity)}</span>
                </div>
            `).join('');
        } else {
            sentSection.classList.add('hidden');
        }
    };

    // Change Cart Quantity
    const changeCartQty = (idx, delta) => {
        state.cart[idx].quantity += delta;
        if (state.cart[idx].quantity <= 0) {
            state.cart.splice(idx, 1);
        }
        localStorage.setItem('cart', JSON.stringify(state.cart));
        renderOrderItems();
    };

    // Remove from Cart
    const removeFromCart = (idx) => {
        state.cart.splice(idx, 1);
        localStorage.setItem('cart', JSON.stringify(state.cart));
        renderOrderItems();
    };

    // Send Orders
    window.sendOrders = async () => {
        const pending = state.cart.filter(c => c.status === 'pending');
        if (pending.length === 0) return;

        const sendingModal = document.getElementById('sending-modal');
        sendingModal.classList.remove('hidden');
        sendingModal.classList.add('flex');

        try {
            const response = await fetch(`${API_BASE}/send_orders.php`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    table_id: state.tableId,
                    order_id: state.orderId,
                    items: pending.map(p => ({
                        item_id: p.item_id,
                        quantity: p.quantity,
                        notes: p.notes
                    }))
                })
            });

            const data = await response.json();

            if (!data.success) throw new Error(data.error);

            // Mark as sent
            state.cart.forEach(item => {
                if (item.status === 'pending') {
                    item.status = 'sent';
                }
            });

            // Save order ID
            if (data.order_id) {
                state.orderId = data.order_id;
                localStorage.setItem('orderId', data.order_id);
            }

            localStorage.setItem('cart', JSON.stringify(state.cart));

            sendingModal.classList.add('hidden');
            sendingModal.classList.remove('flex');

            // Show success
            const successModal = document.getElementById('success-modal');
            successModal.classList.remove('hidden');
            successModal.classList.add('flex');

            renderOrderItems();

        } catch (error) {
            sendingModal.classList.add('hidden');
            sendingModal.classList.remove('flex');
            alert('เกิดข้อผิดพลาด: ' + error.message);
        }
    };

    window.closeSuccessModal = () => {
        const modal = document.getElementById('success-modal');
        modal.classList.add('hidden');
        modal.classList.remove('flex');
    };

    // ==================== BILL PAGE ====================

    const initBillPage = async () => {
        state.tableId = localStorage.getItem('tableId');
        state.tableName = localStorage.getItem('tableName');
        state.orderId = localStorage.getItem('orderId');

        const loading = document.getElementById('loading');

        try {
            const response = await fetch(`${API_BASE}/check_bill.php?table_id=${state.tableId}&order_id=${state.orderId || ''}`);
            const data = await response.json();

            loading.classList.add('hidden');

            if (!data.success) throw new Error(data.error);

            renderBill(data);

        } catch (error) {
            loading.innerHTML = `
                <p class="text-accent">เกิดข้อผิดพลาด</p>
                <p class="text-white/50 mt-2 text-sm">${error.message}</p>
            `;
        }
    };

    const renderBill = (data) => {
        document.getElementById('bill-table').textContent = data.table?.table_name || state.tableName;
        document.getElementById('bill-time').textContent = data.created_at ? new Date(data.created_at).toLocaleTimeString('th-TH', { hour: '2-digit', minute: '2-digit' }) : '--:--';

        // Items
        const itemsContainer = document.getElementById('bill-items');
        itemsContainer.innerHTML = data.items.map(item => `
            <div class="flex items-center justify-between px-6 py-3">
                <div class="flex-1">
                    <span class="font-medium">${item.name}</span>
                    ${item.notes ? `<p class="text-sm text-white/50">${item.notes}</p>` : ''}
                </div>
                <span class="text-white/60 mx-4">x${item.quantity}</span>
                <span class="font-medium min-w-[80px] text-right">฿${formatNumber(item.subtotal)}</span>
            </div>
        `).join('');

        // Summary
        document.getElementById('bill-subtotal').textContent = `฿${formatNumber(data.summary.subtotal)}`;
        document.getElementById('bill-total').textContent = `฿${formatNumber(data.summary.grand_total)}`;

        if (data.summary.discount > 0) {
            document.getElementById('discount-row').classList.remove('hidden');
            document.getElementById('bill-discount').textContent = `-฿${formatNumber(data.summary.discount)}`;
        }
    };

    // Call Waiter
    window.callWaiter = () => {
        const modal = document.getElementById('waiter-modal');
        modal.classList.remove('hidden');
        modal.classList.add('flex');
        // TODO: Send notification to POS
    };

    window.closeWaiterModal = () => {
        const modal = document.getElementById('waiter-modal');
        modal.classList.add('hidden');
        modal.classList.remove('flex');
    };

    // PromptPay
    window.showPromptPayQR = () => {
        // TODO: Generate PromptPay QR
        const modal = document.getElementById('promptpay-modal');
        modal.classList.remove('hidden');
        modal.classList.add('flex');
    };

    window.closePromptPayModal = () => {
        const modal = document.getElementById('promptpay-modal');
        modal.classList.add('hidden');
        modal.classList.remove('flex');
    };

    // Public API
    return {
        init,
        initOrdersPage,
        initBillPage,
        openModal,
        changeCartQty,
        removeFromCart
    };
})();
