let config_counter = 0;

const createNameComponent = function () {
  return /*#__PURE__*/React.createElement("div", {
    class: "flex row no-wrap"
  }, /*#__PURE__*/React.createElement("label", {
    for: "name"
  }, "Service name:"), /*#__PURE__*/React.createElement("input", {
    id: "name",
    name: `settings[${config_counter}][name]`,
    placeholder: "name",
    value: settings?.[config_counter]?.name ?? ''
  }));
};

const createMethodSelectorComponent = function () {
  const METHODS = ['GET', 'POST', 'PUT', 'DELETE'];

  function deleteConfiguration() {
    const configElement = this.parentElement.parentElement;
    configElement.parentElement.removeChild(configElement);
  }

  return /*#__PURE__*/React.createElement("div", {
    class: "flex row no-wrap"
  }, /*#__PURE__*/React.createElement("label", {
    for: "method"
  }, "Method:"), /*#__PURE__*/React.createElement("select", {
    id: "method",
    name: `settings[${config_counter}][method]`
  }, METHODS.map(method => /*#__PURE__*/React.createElement("option", {
    value: method,
    selected: settings?.[config_counter]?.method === method
  }, method))), /*#__PURE__*/React.createElement("input", {
    class: "url",
    name: `settings[${config_counter}][url]`,
    value: settings?.[config_counter]?.url ?? '',
    placeholder: "https://example.com"
  }), /*#__PURE__*/React.createElement("input", {
    type: "button",
    onclick: deleteConfiguration,
    value: "-"
  }));
};

const createRequestBodyComponent = function () {
  return /*#__PURE__*/React.createElement("div", {
    id: "request-body",
    class: "flex row no-wrap"
  }, /*#__PURE__*/React.createElement("label", {
    for: "request-body-input"
  }, "body:"), /*#__PURE__*/React.createElement("input", {
    id: "request-body-input",
    name: `settings[${config_counter}][request_body]`,
    value: settings?.[config_counter]?.request_body ?? ''
  }));
};

const createHeaderComponent = function (value = '', config_id = config_counter) {
  const deleteHeader = function () {
    const header = this.parentElement.parentElement;
    header.parentElement.removeChild(header);
  };

  return /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("span", {
    class: "flex row"
  }, /*#__PURE__*/React.createElement("input", {
    name: `settings[${config_id}][headers][]`,
    value: value,
    placeholder: "Authorization=Token"
  }), /*#__PURE__*/React.createElement("input", {
    type: "button",
    onclick: deleteHeader,
    value: "-"
  })));
};

const createHeadersComponent = function () {
  const addHeaderComponent = (config_id => function () {
    this.previousElementSibling.appendChild(createHeaderComponent('', config_id));
  })(config_counter);

  const headers_values = settings?.[config_counter]?.headers ?? [];
  return /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("details", null, /*#__PURE__*/React.createElement("summary", null, "Headers"), /*#__PURE__*/React.createElement("span", null, headers_values.map(v => createHeaderComponent(v))), /*#__PURE__*/React.createElement("input", {
    type: "button",
    onclick: addHeaderComponent,
    value: "+"
  })));
};

const createTargetFieldComponent = function () {
  return /*#__PURE__*/React.createElement("div", {
    class: "flex row no-wrap"
  }, /*#__PURE__*/React.createElement("label", {
    for: "target_field"
  }, "Target custom field name:"), /*#__PURE__*/React.createElement("select", {
    id: "target_field",
    name: `settings[${config_counter}][target_field]`
  }, custom_fields.map(field => /*#__PURE__*/React.createElement("option", {
    value: field.id,
    selected: settings?.[config_counter]?.target_field == field.id
  }, field.name))));
};

const createEnabledServicesComponent = function () {
  return /*#__PURE__*/React.createElement("div", {
    style: "display: none"
  }, Object.entries(settings?.[config_counter]?.disabled_projects ?? {}).map(([key, value]) => /*#__PURE__*/React.createElement("input", {
    type: "hidden",
    name: `settings[${config_counter}][disabled_projects][${key}]`,
    value: value
  })));
};

const createConfigComponent = function () {
  return /*#__PURE__*/React.createElement("div", {
    class: "flex column card"
  }, createNameComponent(), createMethodSelectorComponent(), createRequestBodyComponent(), createHeadersComponent(), createTargetFieldComponent(), createEnabledServicesComponent());
};

const init = function () {
  const configsElem = document.getElementById('qualification');

  const addConfig = function () {
    config_counter++;
    this.previousElementSibling.appendChild(createConfigComponent());
  };

  const settingsKeys = Object.getOwnPropertyNames(settings);
  configsElem.appendChild( /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("h2", null, "Congfigurations"), /*#__PURE__*/React.createElement("span", {
    id: "configs"
  }, settingsKeys.map(key => (config_counter = Number(key), createConfigComponent()))), /*#__PURE__*/React.createElement("input", {
    type: "button",
    onclick: addConfig,
    value: "+"
  })));
};

window.addEventListener('DOMContentLoaded', init);
