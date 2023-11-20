export async function init(ctx, payload) {
    await importJS(
        "https://cdn.jsdelivr.net/npm/vue@3.2.37/dist/vue.global.prod.js"
    );
    await importJS(
        "https://cdn.jsdelivr.net/npm/vue-dndrop@1.2.13/dist/vue-dndrop.min.js"
    );
    ctx.importCSS(
        "https://fonts.googleapis.com/css2?family=Inter:wght@400;500&display=swap"
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
        template: `
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

        template: `
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
        template: `
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
              @click="$emit('removeOperation')"
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

    const BaseButton = {
        name: "BaseButton",
        props: {
            label: {
                type: String,
                default: "",
            },
        },
        template: `
      <button class="button button--sm button--dashed" type="button" :disabled="noDataFrame"
        @click="$emit('addOperation')">
        <i class="ri-add-line"></i>
        <span class="dashed-button-label">{{ label }}</span>
      </button>
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
        template: `
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
                >
                <div :class="['switch-button-bg', switchClass]" />
              </label>
            </div>
          </div>
        `,
    };

    const BaseMultiTagSelect = {
        name: "BaseMultiTagSelect",

        props: {
            label: {
                type: String,
                default: "",
            },
            message: {
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
            availableOptions(tags, options) {
                return options.filter((option) => !tags.includes(option));
            },
        },
        template: `
      <div v-bind:class="[inline ? 'inline-field' : 'field', 'multiselect']">
        <label v-bind:class="inline ? 'inline-input-label' : 'input-label'">
          {{ label }}
        </label>
        <div class="tags input">
          <div class="tags-wrapper">
            <span class="tag-message" v-if="disabled">{{ message }}</span>
            <span class="tag-pill" v-for="tag in modelValue">
              {{ tag }}
              <button
                class="button button--sm icon-only tag-button"
                @click="$emit('removeInnerValue', tag)"
                type="button"
              >
                <i class="tag-svg ri-close-line ri-xs"></i>
              </button>
            </span>
          </div>
          <select
            :value="modelValue"
            v-bind="$attrs"
            v-bind:disabled="disabled"
            v-bind:class="[selectClass, 'tag-input']"
          >
            <option disabled></option>
            <option
              v-for="option in availableOptions(modelValue, options)"
              :value="option.value || option"
              :selected=""
            >
              {{ option.label || option }}
            </option>
          </select>
        </div>
      </div>
      `,
    };

    const BaseDataList = {
        name: "BaseDataList",

        props: {
            label: {
                type: String,
                default: "",
            },
            message: {
                type: String,
                default: "",
            },
            datalist: {
                type: String,
                default: "datalist",
            },
            inputClass: {
                type: String,
                default: "input",
            },
            modelValue: {
                type: [String, Number],
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
        template: `
      <div v-bind:class="inline ? 'inline-field' : 'field'">
        <label v-bind:class="inline ? 'inline-input-label' : 'input-label'">
          {{ label }}
        </label>
        <input
          :list="datalist"
          :value="modelValue"
          @input="$emit('update:modelValue', $event.target.value)"
          v-bind="$attrs"
          v-bind:class="inputClass"
        >
        <datalist :id="datalist">
          <option v-for="option in options" :value="option">
            {{ option }}
          </option>
        </datalist>
        <div class="validation-wrapper">
          <span class="tooltip right validation-message" :data-tooltip="message" v-if="message">
            <i class="ri-error-warning-fill validation-icon"></i>
          </span>
        </div>
      </div>
      `,
    };

    const app = Vue.createApp({
        components: {
            BaseSelect,
            BaseInput,
            BaseCard,
            BaseButton,
            BaseSwitch,
            BaseMultiTagSelect,
            BaseDataList,
            Container: VueDndrop.Container,
            Draggable: VueDndrop.Draggable,
        },
        template: `
        <div class="app">
        <div class="row">
            <BaseSelect
            name = "instrument"
            label = "Instrument"
            v-model = "instrument"
            :options = "instruments"
            />
            <BaseSelect
            name = "query_key"
            label = "Query"
            v-model = "query_key"
            :options = "query_keys"
            />
        </div>
        </div>
      `,
        data() {
            return {
                models: payload.models,
                instrument: payload.instrument,
                query_key: payload.query_key,
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
                return Object.keys(this.selected_model)
            },
            params() {
                return this.selected_model()[this.query_key] || [];
            },
        }
    }).mount(ctx.root);

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
