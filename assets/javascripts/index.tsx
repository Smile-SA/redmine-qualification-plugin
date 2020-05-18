let config_counter = 0;

const createNameComponent = function() {
    return (
        <div class="flex row no-wrap">
            <label for="name">Service name:</label>
            <input id="name" name={`settings[${config_counter}][name]`} placeholder="name" value={settings?.[config_counter]?.name ?? ''}></input>
        </div>
    )
}

const createMethodSelectorComponent = function() {
    const METHODS = ['GET', 'POST', 'PUT', 'DELETE']

    function deleteConfiguration() {
        const configElement = this.parentElement.parentElement;
        configElement.parentElement.removeChild(configElement);
    }

    return (
        <div class="flex row no-wrap">
            <label for="method">Method:</label>
            <select id="method" name={`settings[${config_counter}][method]`}>
                { METHODS.map(method => <option value={method} selected={settings?.[config_counter]?.method === method}>{method}</option>) }
            </select>
            <input class="url" name={`settings[${config_counter}][url]`} value={settings?.[config_counter]?.url ?? ''} placeholder="https://example.com"></input>
            <input type="button" onclick={deleteConfiguration} value="-"></input>
        </div>
    );
};

const createRequestBodyComponent = function() {
    return (
        <div id="request-body" class="flex row no-wrap">
            <label for="request-body-input">body:</label>
            <input id="request-body-input" name={`settings[${config_counter}][request_body]`} value={settings?.[config_counter]?.request_body ?? ''}></input>
        </div>
    );
};

const createHeaderComponent = function (value = '', config_id = config_counter) {
    const deleteHeader = function() {
        const header = this.parentElement.parentElement;
        header.parentElement.removeChild(header);
    }

    return (
        <div>
            <span class="flex row">
                <input name={`settings[${config_id}][headers][]`} value={value} placeholder="Authorization=Token"></input>
                <input type="button" onclick={deleteHeader} value="-"></input>
            </span>
        </div>
    );
};

const createHeadersComponent = function() {
    const addHeaderComponent = ((config_id) => function () {
        this.previousElementSibling.appendChild(createHeaderComponent('', config_id));
    })(config_counter);

    const headers_values = settings?.[config_counter]?.headers ?? [];

    return (
        <div>
            <details>
                <summary>Headers</summary>
                <span>
                    {headers_values.map((v) => createHeaderComponent(v))}
                </span>
                <input type="button" onclick={addHeaderComponent} value="+"></input>
            </details>
        </div>
    );
};

const createTargetFieldComponent = function() {
    return (
        <div class="flex row no-wrap">
            <label for="target_field">Target custom field name:</label>
            <select id="target_field" name={`settings[${config_counter}][target_field]`}>
                { custom_fields.map(field => <option value={field.id} selected={settings?.[config_counter]?.target_field == field.id}>{field.name}</option>) }
            </select>
        </div>
    );
};

const createEnabledServicesComponent = function() {
    return (
        <div style="display: none">
            {Object.entries(settings?.[config_counter]?.disabled_projects ?? {}).map(([key, value]) => 
                <input type="hidden" name={`settings[${config_counter}][disabled_projects][${key}]`} value={value}></input>
            )}
        </div>
    )
}

const createConfigComponent = function() {
    return (<div class="flex column card">
        {createNameComponent()}
        {createMethodSelectorComponent()}
        {createRequestBodyComponent()}
        {createHeadersComponent()}
        {createTargetFieldComponent()}
        {createEnabledServicesComponent()}
    </div>);
};

const init = function() {
    const configsElem = document.getElementById('qualification');

    const addConfig = function() {
        config_counter++;
        this.previousElementSibling.appendChild(createConfigComponent());
    };

    const settingsKeys = Object.getOwnPropertyNames(settings);

    configsElem.appendChild(
        <div>
            <h2>Congfigurations</h2>
            
            <span id="configs">
                {settingsKeys.map((key) => (config_counter = Number(key), createConfigComponent()))}
            </span>
            <input type="button" onclick={addConfig} value="+"></input>
        </div>
    );
};

window.addEventListener('DOMContentLoaded', init);
