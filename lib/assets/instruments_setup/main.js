export async function init(ctx, payload) {
  await importJS(
    "https://cdn.jsdelivr.net/npm/vue@3.2.37/dist/vue.global.prod.js"
  );
  ctx.importCSS(
    "https://fonts.googleapis.com/css2?family=Inter:wght@400;500&display=swap"
  );
  ctx.importCSS(
    "https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;500;600&display=swap"
  );
  ctx.importCSS(
    "https://cdn.jsdelivr.net/npm/remixicon@3.2.0/fonts/remixicon.min.css"
  );
  ctx.importCSS("main.css");

  const BaseSelect = {
    name: "BaseSelect",

    props: {
      label: {
        type: String,
        default: "",
      },
      selectClass: {
        type: String,
        default: "input",
      },
      modelValue: {
        type: String,
        default: "",
      },
      options: {
        type: Array,
        default: [],
        required: true,
      },
      required: {
        type: Boolean,
        default: false,
      },
      inline: {
        type: Boolean,
        default: false,
      },
      disabled: {
        type: Boolean,
        default: false,
      },
    },
    methods: {
      available(value, options) {
        return value
          ? options.some((option) => option === value || option.value === value)
          : true;
      },
    },
    template: /*HTML*/ `
      <div v-bind:class="inline ? 'inline-field' : 'field'">
        <label v-bind:class="inline ? 'inline-input-label' : 'input-label'">
          {{ label }}
        </label>
        <select
          :value="modelValue"
          v-bind="$attrs"
          v-bind:disabled="disabled"
          @change="$emit('update:modelValue', $event.target.value)"
          v-bind:class="selectClass"
          :class="{ unavailable: !available(modelValue, options) }"
        >
        <option v-if="!required && available(modelValue, options)"></option>
        <option
          v-for="option in options"
          :value="option.value || option"
          :selected="option.value === modelValue || option === modelValue"
        >{{ option.label || option }}</option>
        <option
          v-if="!available(modelValue, options)"
          class="unavailable-option"
          :value="modelValue"
        >{{ modelValue }}</option>
        </select>
      </div>
      `,
  };

  const BaseInput = {
    name: "BaseInput",

    props: {
      label: {
        type: String,
        default: "",
      },
      message: {
        type: String,
        default: "",
      },
      inputClass: {
        type: String,
        default: "input",
      },
      modelValue: {
        type: [String, Number],
        default: "",
      },
      inline: {
        type: Boolean,
        default: false,
      },
      grow: {
        type: Boolean,
        default: false,
      },
    },

    template: /*HTML*/ `
      <div v-bind:class="[inline ? 'inline-field' : 'field', grow ? 'grow' : '']">
        <label v-bind:class="inline ? 'inline-input-label' : 'input-label'">
          {{ label }}
        </label>
        <input
          :value="modelValue"
          @input="$emit('update:modelValue', $event.target.value)"
          v-bind="$attrs"
          v-bind:class="inputClass"
        >
        <div class="validation-wrapper" v-if="message">
          <span class="tooltip right validation-message" :data-tooltip="message">
            <i class="ri-error-warning-fill validation-icon"></i>
          </span>
        </div>
      </div>
      `,
  };

  const BaseCard = {
    name: "BaseCard",
    data() {
      return {
        isOpen: true,
      };
    },
    template: /*HTML*/ `
    <div class="card">
      <div class="card-content">
        <slot name="move" />
        <slot name="content" />
      </div>
      <div class="card-buttons">
        <div class="operation-controls">
          <slot name="toggle"/>
          <button
            class="button button--sm icon-only"
            @click="$emit('removeInstrument')"
            type="button"
          >
            <i class="ri-delete-bin-line button-svg"></i>
          </button>
        </div>
        <div class="card-controls">
          <slot name="controls"></slot>
        </div>
      </div>
    </div>
  `,
  };

  const app = Vue.createApp({
    components: {
      BaseSelect,
      BaseInput,
      BaseCard,
    },
    template: /*HTML*/ `
        <div class="app">
        <form @change="handleFormChange">
            <BaseCard
            v-for = "(spec, index) in specs"
            @remove-instrument="removeInstrument(index)"
            >
              <template v-slot:content>
              <div class="column">
                <div class="row">
                <BaseInput label="Name" v-model="spec.name"/>
                <BaseInput label="Model" v-model="spec.model"/>
                <BaseInput label="Sleep time (ms)" v-model="spec.sleep_after_reply"/>
                <BaseSelect label="Connection type" :options="connection_types" v-model="spec.selected_type">
                </div>
                <div class="row" v-if="spec.selected_type=='Dummy'">
                <BaseSelect label="Random?" v-model="spec.dummy.if_random">
                </div>
                <div class="row" v-if="spec.selected_type=='TCP'">
                <BaseInput label="Address" v-model="spec.tcp.address">
                <BaseInput label="Port number" v-model="spec.tcp.port">
                </div>
                <div class="row" v-if="spec.selected_type=='PyVisa'">
                <BaseInput label="Address" v-model="spec.pyvisa.address">
                </div>
              </div>
              </template>
            </BaseCard>
            <button class="button button--sm button--dashed" type="button" @click="addInstrument">
            <i class="ri-add-line"></i>
            <span class="dashed-button-label">Add</span>
            </button>
        </form>
        </div>
      `,
    data() {
      return {
        specs: payload.specs,
      };
    },

    computed: {
      connection_types() {
        return ["Dummy", "TCP", "PyVisa"];
      },
      true_false() {
        return ["True", "False"];
      },
    },

    methods: {
      handleFormChange(event) {
        console.dir(event);
        console.dir(this.specs);
        ctx.pushEvent("form_changed", { specs: Vue.toRaw(this.specs) });
      },
      addInstrument() {
        ctx.pushEvent("add_instrument", {});
      },
      removeInstrument(index) {
        ctx.pushEvent("remove_instrument", { idx: index });
      },
    },
  }).mount(ctx.root);

  ctx.handleEvent("update_specs", (specs) => {
    app.specs = specs;
  });
}

// Imports a JS script globally using a <script> tag
function importJS(url) {
  return new Promise((resolve, reject) => {
    const scriptEl = document.createElement("script");
    scriptEl.addEventListener(
      "load",
      (event) => {
        resolve();
      },
      { once: true }
    );
    scriptEl.src = url;
    document.head.appendChild(scriptEl);
  });
}
