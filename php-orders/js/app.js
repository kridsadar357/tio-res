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
        modalQty: 1,
        lang: localStorage.getItem('lang') || 'th' // th, en, cn
    };

    // Language config
    const LANG_CONFIG = {
        th: { flag: '🇹🇭', code: 'TH', label: 'ไทย' },
        en: { flag: '🇺🇸', code: 'EN', label: 'English' },
        cn: { flag: '🇨🇳', code: 'CN', label: '中文' }
    };

    // Toggle language menu
    const toggleLangMenu = () => {
        const menu = document.getElementById('lang-menu');
        if (menu) menu.classList.toggle('hidden');
    };

    // Set language
    const setLanguage = (lang) => {
        state.lang = lang;
        localStorage.setItem('lang', lang);

        // Update UI
        const config = LANG_CONFIG[lang];
        const flagEl = document.getElementById('lang-flag');
        const codeEl = document.getElementById('lang-code');
        if (flagEl) flagEl.textContent = config.flag;
        if (codeEl) codeEl.textContent = config.code;

        // Hide menu
        const menu = document.getElementById('lang-menu');
        if (menu) menu.classList.add('hidden');

        // Re-render categories and menu items
        renderCategories();
        renderMenuItems();
    };

    // Get localized name for item/category
    const getLocalizedName = (item) => {
        if (!item) return '';
        switch (state.lang) {
            case 'en':
                return item.name_en || item.name || '';
            case 'cn':
                return item.name_cn || item.name || '';
            case 'th':
            default:
                return item.name_th || item.name || '';
        }
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

        // Check if table is opened before allowing ordering
        if (state.tableId) {
            const tableOk = await checkTableStatus();
            if (!tableOk) return; // Stop if table is not ready
        }

        // Load cart from localStorage
        state.cart = JSON.parse(localStorage.getItem('cart') || '[]');

        // Update UI
        updateTableBadge();
        updateCartButton();

        // Load menu
        await loadMenu();
    };

    // Check if table is opened (status = 1 = occupied)
    const checkTableStatus = async () => {
        const loading = document.getElementById('loading');

        try {
            const response = await fetch(`${API_BASE}/get_table_status.php?table_id=${state.tableId}&table=${state.tableId}`);
            const data = await response.json();

            if (!data.success) {
                throw new Error(data.error || 'ไม่พบข้อมูลโต๊ะ');
            }

            // Check table status: 0=available, 1=occupied, 2=cleaning
            if (data.table.status !== 1) {
                // Table is not opened - show message
                loading.innerHTML = `
                    <div class="text-center p-8">
                        <svg class="w-20 h-20 mx-auto text-accent/60 mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"/>
                        </svg>
                        <h2 class="text-xl font-bold text-white mb-2">โต๊ะยังไม่เปิด</h2>
                        <p class="text-white/60 mb-4">กรุณาแจ้งพนักงานเพื่อเปิดโต๊ะก่อนสั่งอาหาร</p>
                        <p class="text-white/40 text-sm">Table ${state.tableName || state.tableId} is not open</p>
                        <button onclick="location.reload()" class="mt-6 px-8 py-3 bg-primary/20 text-primary rounded-xl hover:bg-primary/30 transition">
                            <svg class="w-5 h-5 inline mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"/>
                            </svg>
                            ลองใหม่
                        </button>
                    </div>
                `;
                return false;
            }

            // Update state with server data
            if (data.table.name) state.tableName = data.table.name;
            if (data.order && data.order.id) state.orderId = data.order.id;

            // Update header UI with store and tier info
            if (data.store) {
                const storeNameEl = document.getElementById('store-name');
                if (storeNameEl) storeNameEl.textContent = data.store.name_th || data.store.name || 'ร้านอาหาร';
            }
            if (data.buffet_tier) {
                const tierNameEl = document.getElementById('tier-name');
                if (tierNameEl) tierNameEl.textContent = data.buffet_tier.name_th || data.buffet_tier.name || 'บุฟเฟ่ต์';
            }

            return true;

        } catch (error) {
            console.error('Table status check failed:', error);
            // If check fails, allow proceeding (graceful degradation)
            return true;
        }
    };

    // Load Menu Items
    const loadMenu = async () => {
        const loading = document.getElementById('loading');
        const menuGrid = document.getElementById('menu-grid');
        const emptyState = document.getElementById('empty-state');

        try {
            // Include table_id for store context (required for public access without API key)
            const url = `${API_BASE}/get_items.php?table=${state.tableId || ''}&tier_id=${state.tierId || ''}`;
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
            btn.className = 'category-btn whitespace-nowrap px-5 py-2.5 rounded-full text-sm font-medium bg-dark-700 text-white/70 hover:bg-dark-600 transition';
            btn.textContent = getLocalizedName(cat);
            btn.onclick = () => selectCategory(cat.id);
            container.appendChild(btn);
        });

        allBtn.onclick = () => selectCategory('all');
    };

    // Select Category
    const selectCategory = (catId) => {
        state.selectedCategory = catId;

        // Update active state - filled primary when active
        document.querySelectorAll('.category-btn').forEach(btn => {
            const isActive = btn.dataset.category == catId;
            if (isActive) {
                btn.className = 'category-btn active whitespace-nowrap px-5 py-2.5 rounded-full text-sm font-medium bg-primary text-dark-900';
            } else {
                btn.className = 'category-btn whitespace-nowrap px-5 py-2.5 rounded-full text-sm font-medium bg-dark-700 text-white/70 hover:bg-dark-600 transition';
            }
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
                    <h3 class="font-medium text-sm line-clamp-2 mb-2">${getLocalizedName(item)}</h3>
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
        document.getElementById('modal-name').textContent = getLocalizedName(item);
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
        const itemName = state.modalItem.name; // Save name before closeModal clears it

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
        showToast(`เพิ่ม ${itemName} แล้ว`); // Use saved name
    };

    // Update Cart Button (Footer)
    const updateCartButton = () => {
        const footer = document.getElementById('cart-footer');
        const countEl = document.getElementById('cart-count');
        const totalEl = document.getElementById('cart-total');

        if (!footer) return;

        const pendingItems = state.cart.filter(c => c.status === 'pending');
        const count = pendingItems.reduce((sum, c) => sum + c.quantity, 0);
        const total = pendingItems.reduce((sum, c) => sum + (c.price * c.quantity), 0);

        if (count > 0) {
            footer.classList.remove('hidden');
            countEl.textContent = count;
            totalEl.textContent = formatNumber(total);
        } else {
            footer.classList.add('hidden');
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
        if (pending.length === 0) {
            alert('ไม่มีรายการที่รอส่ง');
            return;
        }

        const sendingModal = document.getElementById('sending-modal');
        sendingModal.classList.remove('hidden');
        sendingModal.classList.add('flex');

        try {
            console.log('Sending order to API...', {
                table_id: state.tableId,
                order_id: state.orderId,
                items_count: pending.length
            });

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

            // Check HTTP status first
            if (!response.ok) {
                const errorText = await response.text();
                console.error('API Error Response:', response.status, errorText);
                throw new Error(`HTTP ${response.status}: ${errorText}`);
            }

            const data = await response.json();
            console.log('API Response:', data);

            if (!data.success) {
                throw new Error(data.error || data.message || 'Unknown error');
            }

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
            console.error('Send Order Failed:', error);
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
            // Use 'table' param for public access (store identification)
            const response = await fetch(`${API_BASE}/check_bill.php?table=${state.tableId}&table_id=${state.tableId}&order_id=${state.orderId || ''}`);
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
        removeFromCart,
        toggleLangMenu,
        setLanguage
    };
})();
