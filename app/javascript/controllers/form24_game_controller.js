import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { id: Number, hand: Array }

  connect() {
    this.gameId = this.idValue
    this.initialHand = this.handValue || []
    this.items = []
    this.history = []
    this.selectedEntity = null // {type: 'card'|'group', id}
    this.selectedOperator = null
    this.groups = []
    this.nextGroupId = 1
    this.colorPalette = ['#e74c3c', '#3498db', '#2ecc71', '#f1c40f', '#9b59b6']
    this.nextColorIndex = 0
    this.container = document.getElementById('cards-container')
    this.currentDisplay = document.getElementById('current-expression')
    this.resultEl = document.getElementById('result')
    this.buildItemsFromHand()
    this.render()
    this.updateCurrentDisplay()
  }

  buildItemsFromHand() {
    // handValue entries are objects: { code: '10H', url: '/assets/...' }
    this.items = this.initialHand.map((entry, i) => {
      const code = entry.code || entry
      const url = entry.url || null
      return { id: i, type: 'card', code: code, url: url, expr: this.codeToExpr(code), value: this.codeToValue(code) }
    })
    // reset groups when rebuilding hand
    this.groups = []
    this.nextGroupId = 1
    this.nextColorIndex = 0
  }

  codeToValue(code) {
    const rank = code.slice(0, -1)
    if (rank === 'A') return 1
    if (rank === 'J') return 11
    if (rank === 'Q') return 12
    if (rank === 'K') return 13
    return parseInt(rank, 10)
  }

  codeToExpr(code) {
    const v = this.codeToValue(code)
    return String(v)
  }

  render() {
    this.container.innerHTML = ''
    this.items.forEach((it, idx) => {
      const el = document.createElement('div')
      el.className = 'card'
      el.dataset.index = idx
      el.dataset.id = it.id
      // determine group for this card
      const grp = this.findGroupContainingCard(it.id)
      if (it.type === 'card') {
        const img = document.createElement('img')
        img.src = it.url || `/assets/cards/cards-png-320px/${it.code}.png`
        img.alt = it.code
        img.width = 120
        el.appendChild(img)
      }
      if (grp) {
        el.style.borderColor = grp.color
      }
      // highlight selected entity (if selection is this card or this card belongs to selected group)
      if (this.selectedEntity) {
        if (this.selectedEntity.type === 'card' && this.selectedEntity.id === it.id) el.classList.add('selected')
        if (this.selectedEntity.type === 'group') {
          const g = this.groups.find(x => x.id === this.selectedEntity.id)
          if (g && g.members.includes(it.id)) el.classList.add('selected')
        }
      }
      el.addEventListener('click', () => this.cardClicked(idx))
      this.container.appendChild(el)
    })
  }

  cardClicked(idx) {
    const clickedEntity = this.getEntityForCardIndex(idx)

    // No selection yet and no operator: select clicked entity
    if (!this.selectedEntity && !this.selectedOperator) {
      this.selectedEntity = clickedEntity
      this.render()
      this.updateCurrentDisplay()
      return
    }

    // Operator selected and we have a first operand selected -> combine
    if (this.selectedEntity && this.selectedOperator) {
      // if clicked same entity, deselect
      if (this.entitiesEqual(this.selectedEntity, clickedEntity)) {
        this.selectedEntity = null
        this.selectedOperator = null
        this.render()
        this.updateCurrentDisplay()
        return
      }

      this.pushHistory()
      this.combineEntities(this.selectedEntity, clickedEntity, this.selectedOperator)
      this.selectedEntity = null
      this.selectedOperator = null
      this.render()
      this.updateCurrentDisplay()
      return
    }

    // If no operator, just change selection
    if (this.selectedEntity && !this.selectedOperator) {
      if (this.entitiesEqual(this.selectedEntity, clickedEntity)) this.selectedEntity = null
      else this.selectedEntity = clickedEntity
      this.render()
      this.updateCurrentDisplay()
      return
    }
  }

  getEntityForCardIndex(idx) {
    const card = this.items[idx]
    // prefer group if card belongs to a group
    const grp = this.findGroupContainingCard(card.id)
    if (grp) return { type: 'group', id: grp.id }
    return { type: 'card', id: card.id }
  }

  entitiesEqual(a, b) {
    return a && b && a.type === b.type && a.id === b.id
  }

  findGroupContainingCard(cardId) {
    return this.groups.find(g => g.members.includes(cardId)) || null
  }

  getEntityMembers(entity) {
    if (entity.type === 'card') return [entity.id]
    const g = this.groups.find(x => x.id === entity.id)
    return g ? g.members.slice() : []
  }

  getEntityExpr(entity) {
    if (entity.type === 'card') {
      const card = this.items.find(it => it.id === entity.id)
      return card.expr
    }
    const g = this.groups.find(x => x.id === entity.id)
    return g ? g.expr : ''
  }

  chooseOperator(e) {
    const op = e.currentTarget.dataset.op
    // toggle operator
    if (this.selectedOperator === op) this.selectedOperator = null
    else this.selectedOperator = op
    this.updateCurrentDisplay()
  }

  combineEntities(entA, entB, op) {
    const membersA = this.getEntityMembers(entA)
    const membersB = this.getEntityMembers(entB)
    const exprA = this.getEntityExpr(entA)
    const exprB = this.getEntityExpr(entB)
    const expr = `(${exprA}${op}${exprB})`
    // compute numeric value
    const valA = this.getEntityValue(entA)
    const valB = this.getEntityValue(entB)
    let val
    switch (op) {
      case '+': val = valA + valB; break
      case '-': val = valA - valB; break
      case '*': val = valA * valB; break
      case '/': val = valB === 0 ? NaN : valA / valB; break
      default: val = NaN
    }

    // determine color: prefer entA's group color, then entB, otherwise new color
    let color = null
    if (entA.type === 'group') {
      const gA = this.groups.find(x => x.id === entA.id)
      if (gA) color = gA.color
    }
    if (!color && entB.type === 'group') {
      const gB = this.groups.find(x => x.id === entB.id)
      if (gB) color = gB.color
    }
    if (!color) {
      color = this.colorPalette[this.nextColorIndex % this.colorPalette.length]
      this.nextColorIndex += 1
    }

    // remove any groups that are being consumed
    const removeIds = []
    if (entA.type === 'group') removeIds.push(entA.id)
    if (entB.type === 'group') removeIds.push(entB.id)
    this.groups = this.groups.filter(g => !removeIds.includes(g.id))

    // create new group
    const newGroup = { id: this.nextGroupId++, members: Array.from(new Set(membersA.concat(membersB))), expr: expr, value: val, color: color }
    this.groups.push(newGroup)
  }

  getEntityValue(entity) {
    if (entity.type === 'card') {
      const c = this.items.find(it => it.id === entity.id)
      return c.value
    }
    const g = this.groups.find(x => x.id === entity.id)
    return g ? g.value : NaN
  }

  pushHistory() {
    // shallow clone of items array and selected states
    this.history.push({ items: JSON.parse(JSON.stringify(this.items)), groups: JSON.parse(JSON.stringify(this.groups)), selectedEntity: this.selectedEntity, selectedOperator: this.selectedOperator })
    if (this.history.length > 50) this.history.shift()
  }

  undo() {
    const last = this.history.pop()
    if (!last) return
    this.items = last.items
    this.groups = last.groups || []
    this.selectedEntity = last.selectedEntity
    this.selectedOperator = last.selectedOperator
    this.render()
    this.updateCurrentDisplay()
  }

  clear() {
    this.pushHistory()
    this.buildItemsFromHand()
    this.selectedEntity = null
    this.selectedOperator = null
    this.render()
    this.updateCurrentDisplay()
  }

  updateCurrentDisplay() {
    // If there's a single group that covers all cards, show it as the current expression
    if (this.groups.length === 1 && this.groups[0].members.length === this.items.length) {
      const g = this.groups[0]
      this.currentDisplay.innerText = g.expr
      const exprInput = document.querySelector('input[name="expression"]')
      if (exprInput) exprInput.value = g.expr
      if (Math.abs(g.value - 24) < 1e-9) {
        // auto-submit to server to record the win and get a new hand
        this.autoSubmitWin(g.expr)
      }
      return
    }

    // Otherwise, show partial building info
    let text = ''
    if (this.selectedEntity) text += this.getEntityExpr(this.selectedEntity)
    if (this.selectedOperator) text += ` ${this.selectedOperator} `
    this.currentDisplay.innerText = text || '\u00A0'
  }

  // allow form submit to send the current expression to server
  submit(e) {
    e.preventDefault()
    const exprInput = document.querySelector('input[name="expression"]')
    const expr = exprInput ? exprInput.value : (this.items.length === 1 ? this.items[0].expr : '')
    const token = document.querySelector('meta[name="csrf-token"]').content
    const gameId = this.gameId

    fetch(`/form24_games/${gameId}/validate`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': token,
        'Accept': 'application/json'
      },
      body: JSON.stringify({ expression: expr })
    }).then(r => r.json().then(j => ({ ok: r.ok, body: j })))
      .then(resp => {
        const out = document.getElementById('result')
        if (resp.ok) {
          out.innerText = resp.body.message || 'Correct!'
          out.style.color = 'green'
        } else {
          out.innerText = resp.body.error || 'Incorrect'
          out.style.color = 'red'
        }
      }).catch(err => {
        const out = document.getElementById('result')
        out.innerText = 'Network error'
        out.style.color = 'red'
      })
  }

  autoSubmitWin(expr) {
    if (this._autoSubmitting) return
    this._autoSubmitting = true
    const token = document.querySelector('meta[name="csrf-token"]').content
    fetch(`/form24_games/${this.gameId}/validate`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': token,
        'Accept': 'application/json'
      },
      body: JSON.stringify({ expression: expr })
    }).then(r => r.json()).then(json => {
      this._autoSubmitting = false
      if (json.ok) {
        // refresh UI: replace hand and reset client state
        if (json.hand) {
          this.initialHand = json.hand.map(h => (typeof h === 'string' ? { code: h, url: `/assets/cards/cards-png-320px/${h}.png` } : { code: h['code'], url: h['url'] }))
          this.buildItemsFromHand()
          this.history = []
          this.groups = []
          this.render()
          this.updateCurrentDisplay()
        }
        // update counters
        const drawsEl = document.getElementById('draws-count')
        const penaltyEl = document.getElementById('penalty-count')
        const scoreEl = document.getElementById('score-count')
        if (drawsEl) drawsEl.innerText = json.draws
        if (penaltyEl) penaltyEl.innerText = json.penalty
        if (scoreEl) scoreEl.innerText = json.score
        if (this.resultEl) {
          this.resultEl.innerText = json.message || 'You made 24 — new hand dealt.'
          this.resultEl.style.color = 'green'
        }
      } else {
        if (this.resultEl) {
          this.resultEl.innerText = json.error || 'Validation failed'
          this.resultEl.style.color = 'red'
        }
      }
    }).catch(err => {
      this._autoSubmitting = false
      if (this.resultEl) {
        this.resultEl.innerText = 'Network error'
        this.resultEl.style.color = 'red'
      }
    })
  }
}
