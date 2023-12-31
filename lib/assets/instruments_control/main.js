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
    template: html`
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
          >
            {{ option.label || option }}
          </option>
          <option
            v-if="!available(modelValue, options)"
            class="unavailable-option"
            :value="modelValue"
          >
            {{ modelValue }}
          </option>
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

    template: html`
      <div
        v-bind:class="[inline ? 'inline-field' : 'field', grow ? 'grow' : '']"
      >
        <label v-bind:class="inline ? 'inline-input-label' : 'input-label'">
          {{ label }}
        </label>
        <input
          :value="modelValue"
          @input="$emit('update:modelValue', $event.target.value)"
          v-bind="$attrs"
          v-bind:class="inputClass"
        />
        <div class="validation-wrapper" v-if="message">
          <span
            class="tooltip right validation-message"
            :data-tooltip="message"
          >
            <i class="ri-error-warning-fill validation-icon"></i>
          </span>
        </div>
      </div>
    `,
  };

  const BaseSwitch = {
    props: {
      label: {
        type: String,
        default: "",
      },
      modelValue: {
        type: Boolean,
      },
      fieldClass: {
        type: String,
        default: "field",
      },
      switchClass: {
        type: String,
        default: "default",
      },
    },
    template: html`
      <div :class="[inner ? 'inner-field' : fieldClass]">
        <label class="input-label"> {{ label }} </label>
        <div class="input-container">
          <label class="switch-button">
            <input
              :checked="modelValue"
              type="checkbox"
              @input="$emit('update:modelValue', $event.target.checked)"
              v-bind="$attrs"
              :class="['switch-button-checkbox', switchClass]"
            />
            <div :class="['switch-button-bg', switchClass]" />
          </label>
        </div>
      </div>
    `,
  };

  const app = Vue.createApp({
    components: {
      BaseSelect,
      BaseInput,
      BaseSwitch,
    },
    template: html`
      <div class="app">
        <div class="container">
          <div class="root">
            <label class="input-label">Instrument control</label>
          </div>
          <div class="row">
            <BaseSelect
              name="instrument"
              label="Instrument"
              v-model="instrument"
              :options="instruments"
              required="true"
            />
            <BaseSelect
              name="query_key"
              label="Query"
              v-model="query_key"
              :options="query_keys"
            />
            <button class="button" type="button" @click="sendQuery">
              Send
            </button>
          </div>
          <div class="row">
            <BaseInput
              v-for="param in params"
              v-model="param.value"
              :key="param.key"
              :name="param.key"
              :label="param.key"
            />
          </div>
          <div class="row" v-if="query_key==''">
            <BaseInput label="Text" v-model="query_text"/>
            <BaseSwitch label="Write only" v-model="if_write_only"/>
          </div>
          <div class="row">
            <div class="field">
              <label class="input-label">Answer</label>
              <span class="script">{{answer}}</span>
            </div>
          </div>
        </div>
      </div>
    `,
    data() {
      return {
        models: payload.models,
        instrument: payload.instrument,
        query_key: payload.query_key,
        answer: payload.answer,
        query_text: payload.query_text,
        if_write_only: payload.if_write_only,
      };
    },

    computed: {
      instruments() {
        return Object.keys(this.models);
      },
      selected_model() {
        return this.models[this.instrument] || {};
      },
      query_keys() {
        return Object.keys(this.selected_model);
      },
      params() {
        return this.selected_model[this.query_key] || [];
      },
    },

    methods: {
      sendQuery() {
        const params = Vue.toRaw(this.params);
        ctx.pushEvent("send_query", {
          instrument: this.instrument,
          query_key: this.query_key,
          params: params,
          query_text: this.query_text,
          if_write_only: this.if_write_only,
        });
      },
    },
  }).mount(ctx.root);

  ctx.handleEvent("update_answer", (answer) => {
    app.answer = answer;
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

export const html = (literals, ...placeholders) => {
  let result = "";
  placeholders.forEach((placeholder, i) => {
    result += literals[i];
    result += placeholder;
  });
  result += literals[literals.length - 1];
  return result;
};
