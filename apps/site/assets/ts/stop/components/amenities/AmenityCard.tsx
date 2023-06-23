import React, { ReactElement, useContext, useState } from "react";
import renderFa from "../../../helpers/render-fa";
import Modal from "../../../components/Modal";

const AmenityModalContext = React.createContext({
  closeModal: () => {}
});

export const AmenityModal = ({
  headerText,
  children
}: {
  headerText: string;
  children?: JSX.Element[] | JSX.Element;
}): ReactElement => {
  const elementId = headerText.toLowerCase().replace(/[ _]/g, "-");
  const { closeModal } = useContext(AmenityModalContext);
  return (
    <Modal
      className="c-amenity-modal"
      closeModal={closeModal}
      ariaLabel={{ elementId }}
    >
      <h1 id={elementId} className="h4">
        {headerText}
      </h1>
      {children}
    </Modal>
  );
};

const AmenityCard = ({
  headerText,
  icon,
  modalContent,
  children
}: {
  headerText: string;
  icon: JSX.Element;
  modalContent?: JSX.Element[] | JSX.Element;
  children?: JSX.Element[] | JSX.Element;
}): JSX.Element => {
  const [modalOpen, setModalOpen] = useState(false);
  return (
    <>
      <button
        type="button"
        className="c-descriptive-link justify-content-space-between"
        onClick={() => setModalOpen(true)}
      >
        <div className="p-16">
          <div className="d-flex text-primary">
            {icon}
            <div className="c-descriptive-link__title ps-8 mb-0">
              {headerText}
            </div>
          </div>
          {children && (
            <div className="c-descriptive-link__text pt-8 hidden-sm-down">
              {children}
            </div>
          )}
        </div>
        <div className="c-descriptive-link__caret-wrapper">
          {renderFa("c-descriptive-link__caret", "fa-angle-right")}
        </div>
      </button>
      <AmenityModalContext.Provider
        value={{ closeModal: () => setModalOpen(false) }}
      >
        {modalOpen && modalContent}
      </AmenityModalContext.Provider>
    </>
  );
};

export default AmenityCard;